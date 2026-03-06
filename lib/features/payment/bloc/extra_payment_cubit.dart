import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/emi_schedule_model.dart';
import '../../../models/loan_model.dart';
import '../../../utils/loan_recalculator.dart';
import '../data/extra_payment_repository.dart';
import 'extra_payment_state.dart';

class ExtraPaymentCubit extends Cubit<ExtraPaymentState> {
  final ExtraPaymentRepository _repo;
  final String loanId;

  ExtraPaymentCubit(this._repo, this.loanId) : super(ExtraPaymentInitial());

  Future<void> loadLoan() async {
    emit(ExtraPaymentLoading());
    try {
      final loan     = await _repo.getLoan(loanId);
      final schedule = await _repo.getPendingSchedule(loanId);
      emit(ExtraPaymentLoanLoaded(loan, schedule));
    } catch (e) {
      emit(ExtraPaymentError(e.toString()));
    }
  }

  /// Preview recalculation without committing anything
  void previewRecalc({
    required LoanModel               loan,
    required double                  extraAmount,
    required List<EmiScheduleModel>  pendingSchedule,
  }) {
    if (extraAmount <= 0 || extraAmount >= loan.remainingPrincipal) {
      emit(ExtraPaymentError(
          'Extra amount must be between ₹1 and ₹${loan.remainingPrincipal - 1}'));
      return;
    }

    final remainingMonths = pendingSchedule.isNotEmpty
        ? pendingSchedule.length
        : 1; // guard against 0 to prevent division-by-zero
    final nextDue = pendingSchedule.isNotEmpty
        ? pendingSchedule.first.dueDate
        : DateTime.now();

    final recalc = LoanRecalculator.recalculate(
      remainingPrincipal: loan.remainingPrincipal,
      extraAmount:        extraAmount,
      annualRate:         loan.interestRate,
      remainingMonths:    remainingMonths,
      originalEmiAmount:  loan.emiAmount,
      nextEmiDate:        nextDue,
      emiDayOfMonth:      loan.emiDate,
      mode:               loan.modeOnExtraPayment,
    );

    emit(ExtraPaymentPreviewReady(
      loan:            loan,
      pendingSchedule: pendingSchedule,
      extraAmount:     extraAmount,
      recalc:          recalc,
    ));
  }

  Future<void> confirmPayment({
    required LoanModel    loan,
    required double       extraAmount,
    required RecalcResult recalc,
    File?                 proofFile,
  }) async {
    emit(ExtraPaymentLoading());
    try {
      await _repo.submitExtraPayment(
        loan:        loan,
        extraAmount: extraAmount,
        recalc:      recalc,
        proofFile:   proofFile,
      );
      emit(ExtraPaymentSuccess());
    } catch (e) {
      emit(ExtraPaymentError(e.toString()));
    }
  }

  void previewClosure(LoanModel loan) {
    emit(ExtraPaymentClosurePreview(loan));
  }

  Future<void> confirmClosure({
    required LoanModel loan,
    File?              proofFile,
  }) async {
    emit(ExtraPaymentLoading());
    try {
      await _repo.closeLoan(loan: loan, proofFile: proofFile);
      emit(ExtraPaymentSuccess(loanClosed: true));
    } catch (e) {
      emit(ExtraPaymentError(e.toString()));
    }
  }

  void reset(LoanModel loan, List<EmiScheduleModel> pendingSchedule) =>
      emit(ExtraPaymentLoanLoaded(loan, pendingSchedule));
}
