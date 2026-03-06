import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../models/payment_model.dart';

class LoanDetailRepository {
  final _uid = supabase.auth.currentUser!.id;

  Future<LoanModel> getLoan(String loanId) async {
    debugPrint('[LoanDetail] getLoan → loanId=$loanId');
    final data = await supabase
        .from('loans')
        .select('''
          *,
          lender:profiles!lender_id(name),
          borrower:profiles!borrower_id(name)
        ''')
        .eq('id', loanId)
        .single();
    data['lender_name']   = data['lender']?['name'];
    data['borrower_name'] = data['borrower']?['name'];
    debugPrint('[LoanDetail] getLoan ✓');
    return LoanModel.fromMap(data);
  }

  Future<List<EmiScheduleModel>> getSchedule(String loanId) async {
    debugPrint('[LoanDetail] getSchedule → loanId=$loanId');
    final data = await supabase
        .from('emi_schedule')
        .select()
        .eq('loan_id', loanId)
        .order('emi_number', ascending: true);
    final list = (data as List).map((m) => EmiScheduleModel.fromMap(m)).toList();
    debugPrint('[LoanDetail] getSchedule ✓ count=${list.length}');
    return list;
  }

  Future<List<PaymentModel>> getPayments(String loanId) async {
    debugPrint('[LoanDetail] getPayments → loanId=$loanId');
    final data = await supabase
        .from('payments')
        .select()
        .eq('loan_id', loanId)
        .order('payment_date', ascending: false);
    final list = (data as List).map((m) => PaymentModel.fromMap(m)).toList();
    debugPrint('[LoanDetail] getPayments ✓ count=${list.length}');
    return list;
  }

  /// Borrower marks EMI as paid (with optional proof image)
  Future<void> markEmiPaid({
    required String loanId,
    required String lenderId,
    required String emiScheduleId,
    required double amount,
    required String borrowerName,
    File?           proofFile,
  }) async {
    debugPrint('[LoanDetail] markEmiPaid → emiScheduleId=$emiScheduleId amount=$amount');
    String? proofUrl;

    if (proofFile != null) {
      final path = 'proofs/$loanId/$emiScheduleId.jpg';
      debugPrint('[LoanDetail] uploading proof → path=$path');
      await supabase.storage.from('payment-proofs').upload(
            path,
            proofFile,
            fileOptions: const FileOptions(upsert: true),
          );
      proofUrl =
          supabase.storage.from('payment-proofs').getPublicUrl(path);
      debugPrint('[LoanDetail] proof upload ✓ url=$proofUrl');
    }

    // Insert payment record
    debugPrint('[LoanDetail] inserting payment record →');
    await supabase.from('payments').insert({
      'loan_id':           loanId,
      'emi_schedule_id':   emiScheduleId,
      'paid_by':           _uid,
      'received_by':       lenderId,
      'amount':            amount,
      'type':              'emi',
      'proof_url':         proofUrl,
      'borrower_approved': true,
      'lender_approved':   false,
    });
    debugPrint('[LoanDetail] payment insert ✓');

    // Update EMI status to 'paid' (awaiting lender approval)
    debugPrint('[LoanDetail] updating emi_schedule status → paid');
    await supabase
        .from('emi_schedule')
        .update({'status': 'paid'})
        .eq('id', emiScheduleId);
    debugPrint('[LoanDetail] emi_schedule update ✓');

    // Notify lender
    try {
      debugPrint('[LoanDetail] notify lender →');
      await supabase.from('notifications').insert({
        'user_id': lenderId,
        'title':   'Payment Marked',
        'body':    '$borrowerName has marked an EMI as paid. Please verify and approve.',
        'type':    'payment_received',
        'loan_id': loanId,
        'is_read': false,
      });
      debugPrint('[LoanDetail] notify lender ✓');
    } catch (e) {
      debugPrint('⚠️ [LoanDetail] Notification insert failed: $e');
    }
  }

  /// Lender approves a payment
  Future<void> approvePayment(String paymentId, {String lenderName = 'Lender'}) async {
    debugPrint('[LoanDetail] approvePayment → paymentId=$paymentId');

    // Fetch payment type BEFORE calling RPC — closure payments must bypass the
    // RPC because it tries to subtract emi_schedule.principal_component from
    // remaining_principal, which is NULL for closure payments (no emi_schedule_id).
    final pmt = await supabase
        .from('payments')
        .select('paid_by, loan_id, amount, type')
        .eq('id', paymentId)
        .single();

    final isClosure = pmt['type'] == 'closure';

    if (isClosure) {
      debugPrint('[LoanDetail] closure payment — bypassing RPC →');

      // Manually approve the payment
      await supabase
          .from('payments')
          .update({'lender_approved': true})
          .eq('id', paymentId);
      debugPrint('[LoanDetail] closure payment approved ✓');

      // Delete all remaining unpaid EMIs
      await supabase
          .from('emi_schedule')
          .delete()
          .eq('loan_id', pmt['loan_id'])
          .inFilter('status', ['pending', 'overdue', 'paid']);
      debugPrint('[LoanDetail] pending EMIs deleted ✓');

      // Close the loan
      await supabase.from('loans').update({
        'status':              'closed',
        'remaining_principal': 0,
      }).eq('id', pmt['loan_id']);
      debugPrint('[LoanDetail] loan closed ✓');

      // Notify borrower
      try {
        await supabase.from('notifications').insert({
          'user_id': pmt['paid_by'],
          'title':   'Loan Closed',
          'body':    '$lenderName approved your full payment of ₹${pmt['amount']}. Loan is now closed!',
          'type':    'loan_closed',
          'loan_id': pmt['loan_id'],
          'is_read': false,
        });
        debugPrint('[LoanDetail] notify borrower (loan closed) ✓');
      } catch (e) {
        debugPrint('⚠️ [LoanDetail] Closure notification failed: $e');
      }
    } else {
      // Regular EMI / extra payment — use the RPC
      await supabase.rpc('approve_payment', params: {
        'p_payment_id':  paymentId,
        'p_approver_id': _uid,
      });
      debugPrint('[LoanDetail] approvePayment RPC ✓');

      // Notify borrower
      try {
        await supabase.from('notifications').insert({
          'user_id': pmt['paid_by'],
          'title':   'Payment Approved',
          'body':    '$lenderName approved your payment of ₹${pmt['amount']}.',
          'type':    'payment_approved',
          'loan_id': pmt['loan_id'],
          'is_read': false,
        });
        debugPrint('[LoanDetail] notify borrower approval ✓');
      } catch (e) {
        debugPrint('⚠️ [LoanDetail] Notification insert failed: $e');
      }
    }
  }

  /// Lender rejects a payment
  Future<void> rejectPayment(String paymentId, String reason, {String lenderName = 'Lender'}) async {
    debugPrint('[LoanDetail] rejectPayment → paymentId=$paymentId reason=$reason');
    await supabase.from('payments').update({
      'lender_approved':  false,
      'rejection_reason': reason,
    }).eq('id', paymentId);
    debugPrint('[LoanDetail] rejectPayment update ✓');

    final pmt = await supabase
        .from('payments')
        .select('emi_schedule_id, paid_by')
        .eq('id', paymentId)
        .single();

    if (pmt['emi_schedule_id'] != null) {
      debugPrint('[LoanDetail] reverting emi_schedule to pending →');
      await supabase
          .from('emi_schedule')
          .update({'status': 'pending'})
          .eq('id', pmt['emi_schedule_id']);
      debugPrint('[LoanDetail] emi_schedule revert ✓');
    }

    // Notify borrower
    try {
      debugPrint('[LoanDetail] notify borrower rejection →');
      await supabase.from('notifications').insert({
        'user_id': pmt['paid_by'],
        'title':   'Payment Rejected',
        'body':    '$lenderName rejected your EMI payment: $reason',
        'type':    'payment_rejected',
        'is_read': false,
      });
      debugPrint('[LoanDetail] notify borrower rejection ✓');
    } catch (e) {
      debugPrint('⚠️ [LoanDetail] Notification insert failed: $e');
    }
  }

  /// Lender deletes a loan (cascades via DB foreign keys)
  Future<void> deleteLoan(String loanId) async {
    debugPrint('[LoanDetail] deleteLoan → loanId=$loanId');
    final deleted = await supabase
        .from('loans')
        .delete()
        .eq('id', loanId)
        .select('id');
    if ((deleted as List).isEmpty) {
      debugPrint('[LoanDetail] deleteLoan ✗ — 0 rows deleted (check RLS policy)');
      throw Exception('Delete failed: no rows affected. Check Supabase RLS policy for loans DELETE.');
    }
    debugPrint('[LoanDetail] deleteLoan ✓');
  }
}
