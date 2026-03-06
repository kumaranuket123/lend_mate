import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../utils/loan_recalculator.dart';

class ExtraPaymentRepository {
  final _uid = supabase.auth.currentUser!.id;

  Future<LoanModel> getLoan(String loanId) async {
    debugPrint('[ExtraPayment] getLoan → loanId=$loanId');
    final data = await supabase
        .from('loans')
        .select(
            '*, lender:profiles!lender_id(name), borrower:profiles!borrower_id(name)')
        .eq('id', loanId)
        .single();
    data['lender_name']   = data['lender']?['name'];
    data['borrower_name'] = data['borrower']?['name'];
    debugPrint('[ExtraPayment] getLoan ✓');
    return LoanModel.fromMap(data);
  }

  Future<List<EmiScheduleModel>> getPendingSchedule(String loanId) async {
    debugPrint('[ExtraPayment] getPendingSchedule → loanId=$loanId');
    final data = await supabase
        .from('emi_schedule')
        .select()
        .eq('loan_id', loanId)
        .inFilter('status', ['pending', 'overdue'])
        .order('emi_number');
    final list = (data as List).map((m) => EmiScheduleModel.fromMap(m)).toList();
    debugPrint('[ExtraPayment] getPendingSchedule ✓ count=${list.length}');
    return list;
  }

  Future<void> closeLoan({
    required LoanModel loan,
    File?              proofFile,
  }) async {
    // Fetch fresh remaining principal from DB to avoid stale data
    final fresh = await supabase
        .from('loans')
        .select('remaining_principal')
        .eq('id', loan.id)
        .single();
    final remaining =
        (fresh['remaining_principal'] as num?)?.toDouble() ?? 0.0;
    debugPrint('[ExtraPayment] closeLoan → loanId=${loan.id} remaining=$remaining');

    // Insert payment record — loan stays active until lender approves
    if (remaining > 0) {
      String? proofUrl;
      if (proofFile != null) {
        final path =
            'proofs/${loan.id}/closure_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint('[ExtraPayment] uploading closure proof → path=$path');
        await supabase.storage.from('payment-proofs').upload(
              path,
              proofFile,
              fileOptions: const FileOptions(upsert: true),
            );
        proofUrl =
            supabase.storage.from('payment-proofs').getPublicUrl(path);
        debugPrint('[ExtraPayment] closure proof upload ✓');
      }

      debugPrint('[ExtraPayment] inserting closure payment →');
      await supabase.from('payments').insert({
        'loan_id':           loan.id,
        'paid_by':           _uid,
        'received_by':       loan.lenderId,
        'amount':            remaining,
        'type':              'closure',
        'proof_url':         proofUrl,
        'borrower_approved': true,
        'lender_approved':   false,
      });
      debugPrint('[ExtraPayment] closure payment insert ✓');
    } else {
      debugPrint('[ExtraPayment] remaining=0, skipping payment insert');
    }

    // Loan stays active — lender must approve to finalise closure
    // Notify lender to review and approve
    try {
      debugPrint('[ExtraPayment] notify lender (closure pending) →');
      await supabase.from('notifications').insert({
        'user_id': loan.lenderId,
        'title':   'Full Payment Received',
        'body':    '${loan.borrowerName ?? 'Borrower'} has submitted a full payment of ₹$remaining. Please approve to close the loan.',
        'type':    'loan_closed',
        'loan_id': loan.id,
        'is_read': false,
      });
      debugPrint('[ExtraPayment] notify lender (closure) ✓');
    } catch (e) {
      debugPrint('⚠️ [ExtraPayment] Closure notification failed: $e');
    }
  }

  Future<void> submitExtraPayment({
    required LoanModel    loan,
    required double       extraAmount,
    required RecalcResult recalc,
    File?                 proofFile,
  }) async {
    debugPrint('[ExtraPayment] submitExtraPayment → loanId=${loan.id} amount=$extraAmount');
    String? proofUrl;
    if (proofFile != null) {
      final path =
          'proofs/${loan.id}/extra_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('[ExtraPayment] uploading proof → path=$path');
      await supabase.storage.from('payment-proofs').upload(
            path,
            proofFile,
            fileOptions: const FileOptions(upsert: true),
          );
      proofUrl =
          supabase.storage.from('payment-proofs').getPublicUrl(path);
      debugPrint('[ExtraPayment] proof upload ✓ url=$proofUrl');
    }

    // 1. Payment record
    debugPrint('[ExtraPayment] inserting payment record →');
    await supabase.from('payments').insert({
      'loan_id':           loan.id,
      'paid_by':           _uid,
      'received_by':       loan.lenderId,
      'amount':            extraAmount,
      'type':              'extra',
      'proof_url':         proofUrl,
      'borrower_approved': true,
      'lender_approved':   false,
    });
    debugPrint('[ExtraPayment] payment insert ✓');

    // 2. Delete old pending/overdue EMI rows
    debugPrint('[ExtraPayment] deleting old pending/overdue EMIs →');
    await supabase
        .from('emi_schedule')
        .delete()
        .eq('loan_id', loan.id)
        .inFilter('status', ['pending', 'overdue']);
    debugPrint('[ExtraPayment] old EMIs deleted ✓');

    // 3. Determine renumber offset — include both 'approved' and 'paid'
    //    ('paid' EMIs are awaiting lender approval and were NOT deleted above)
    final maxRes = await supabase
        .from('emi_schedule')
        .select('emi_number')
        .eq('loan_id', loan.id)
        .inFilter('status', ['approved', 'paid'])
        .order('emi_number', ascending: false)
        .limit(1);
    final offset =
        maxRes.isNotEmpty ? (maxRes.first['emi_number'] as int) : 0;
    debugPrint('[ExtraPayment] emi offset=$offset (approved+paid count)');

    // 4. Insert recalculated schedule (guard against empty list)
    debugPrint('[ExtraPayment] inserting recalculated schedule → count=${recalc.newSchedule.length}');
    if (recalc.newSchedule.isNotEmpty) {
      await supabase.from('emi_schedule').insert(
        recalc.newSchedule.asMap().entries.map((e) => {
          'loan_id':             loan.id,
          'emi_number':          offset + e.key + 1,
          'due_date':
              e.value.dueDate.toIso8601String().substring(0, 10),
          'emi_amount':          e.value.emiAmount,
          'principal_component': e.value.principal,
          'interest_component':  e.value.interest,
          'opening_balance':     e.value.opening,
          'closing_balance':     e.value.closing,
          'status':              'pending',
        }).toList(),
      );
      debugPrint('[ExtraPayment] schedule insert ✓');
    } else {
      debugPrint('[ExtraPayment] newSchedule is empty — skipping insert');
    }

    // 5. Update loan
    debugPrint('[ExtraPayment] updating loan remainingPrincipal=${recalc.newRemainingPrincipal} →');
    await supabase.from('loans').update({
      'remaining_principal': recalc.newRemainingPrincipal,
      if (recalc.newTenureMonths != null)
        'tenure_months': offset + recalc.newTenureMonths!,
      if (recalc.newEmiAmount != null) 'emi_amount': recalc.newEmiAmount,
    }).eq('id', loan.id);
    debugPrint('[ExtraPayment] loan update ✓');

    // 6. Notify lender
    try {
      debugPrint('[ExtraPayment] notify lender →');
      await supabase.from('notifications').insert({
        'user_id': loan.lenderId,
        'title':   'Extra Payment Received',
        'body':    '${loan.borrowerName ?? 'Borrower'} paid an extra ₹$extraAmount. Loan recalculated.',
        'type':    'extra_payment',
        'loan_id': loan.id,
        'is_read': false,
      });
      debugPrint('[ExtraPayment] notify lender ✓');
    } catch (e) {
      debugPrint('⚠️ [ExtraPayment] Notification insert failed: $e');
    }
  }
}
