import 'package:flutter/foundation.dart';
import '../../../core/supabase_client.dart';
import '../../../models/loan_model.dart';
import '../../../models/profile_model.dart';
import '../../../utils/emi_calculator.dart';

class LoanRepository {
  /// Search users by name or phone (for borrower picker)
  Future<List<ProfileModel>> searchUsers(String query) async {
    debugPrint('[Loan] searchUsers → query=$query');
    final uid  = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select()
        .neq('id', uid)
        .or('name.ilike.%$query%,phone.ilike.%$query%')
        .limit(10);
    final results = (data as List).map((m) => ProfileModel.fromMap(m)).toList();
    debugPrint('[Loan] searchUsers ✓ count=${results.length}');
    return results;
  }

  Future<LoanModel> createLoan({
    required String   borrowerId,
    required double   amount,
    required double   interestRate,
    required int      tenureMonths,
    required DateTime startDate,
    required int      emiDate,
    String? lenderUpi,
    String? borrowerUpi,
    String? notes,
    String modeOnExtraPayment = 'reduce_tenure',
  }) async {
    debugPrint('[Loan] createLoan → amount=$amount rate=$interestRate tenure=$tenureMonths');
    final lenderId = supabase.auth.currentUser!.id;
    final emiAmt   = EmiCalculator.emi(amount, interestRate, tenureMonths);
    final total    = EmiCalculator.totalPayable(emiAmt, tenureMonths);
    final interest = EmiCalculator.totalInterest(amount, emiAmt, tenureMonths);

    // 1. Insert loan
    final loanData = await supabase.from('loans').insert({
      'lender_id':             lenderId,
      'borrower_id':           borrowerId,
      'amount':                amount,
      'interest_rate':         interestRate,
      'tenure_months':         tenureMonths,
      'start_date':            startDate.toIso8601String().substring(0, 10),
      'emi_date':              emiDate,
      'emi_amount':            emiAmt,
      'total_interest':        interest,
      'total_payable':         total,
      'remaining_principal':   amount,
      'mode_on_extra_payment': modeOnExtraPayment,
      'lender_upi':            lenderUpi,
      'borrower_upi':          borrowerUpi,
      'notes':                 notes,
      'status':                'active',
    }).select().single();

    final loanId   = loanData['id'] as String;
    debugPrint('[Loan] createLoan ✓ loanId=$loanId → inserting ${tenureMonths} EMI rows');

    final schedule = EmiCalculator.schedule(
        amount, interestRate, tenureMonths, startDate, emiDate);

    // 2. Insert EMI schedule rows
    await supabase.from('emi_schedule').insert(
      schedule.map((r) => {
        'loan_id':             loanId,
        'emi_number':          r.number,
        'due_date':            r.dueDate.toIso8601String().substring(0, 10),
        'emi_amount':          r.emiAmount,
        'principal_component': r.principal,
        'interest_component':  r.interest,
        'opening_balance':     r.opening,
        'closing_balance':     r.closing,
        'status':              'pending',
      }).toList(),
    );
    debugPrint('[Loan] emi_schedule insert ✓');

    // 3. Notify borrower
    try {
      debugPrint('[Loan] notify borrower →');
      await supabase.from('notifications').insert({
        'user_id': borrowerId,
        'title':   'New Loan Created',
        'body':    'A loan of ₹$amount has been created for you.',
        'type':    'loan_created',
        'loan_id': loanId,
        'is_read': false,
      });
      debugPrint('[Loan] notify borrower ✓');
    } catch (e) {
      debugPrint('⚠️ [Loan] Notification insert failed: $e');
    }

    return LoanModel.fromMap(loanData);
  }
}
