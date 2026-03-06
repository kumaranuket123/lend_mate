import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/loan_detail_repository.dart';
import 'loan_detail_state.dart';

class LoanDetailCubit extends Cubit<LoanDetailState> {
  final LoanDetailRepository _repo;
  final String loanId;
  LoanDetailCubit(this._repo, this.loanId) : super(LoanDetailInitial());

  LoanDetailLoaded? _last;

  Future<void> load() async {
    emit(LoanDetailLoading());
    try {
      final results = await Future.wait([
        _repo.getLoan(loanId),
        _repo.getSchedule(loanId),
        _repo.getPayments(loanId),
      ]);
      _last = LoanDetailLoaded(
        loan:     results[0] as dynamic,
        schedule: results[1] as dynamic,
        payments: results[2] as dynamic,
      );
      emit(_last!);
    } catch (e) {
      emit(LoanDetailError(e.toString()));
    }
  }

  Future<void> markEmiPaid({
    required String emiScheduleId,
    required double amount,
    File?           proofFile,
  }) async {
    if (_last == null) return;
    emit(LoanDetailActionLoading());
    try {
      await _repo.markEmiPaid(
        loanId:        loanId,
        lenderId:      _last!.loan.lenderId,
        emiScheduleId: emiScheduleId,
        amount:        amount,
        borrowerName:  _last!.loan.borrowerName ?? 'Borrower',
        proofFile:     proofFile,
      );
      emit(LoanDetailActionSuccess('EMI marked as paid!'));
      await load();
    } catch (e) {
      emit(LoanDetailActionError(e.toString()));
      if (_last != null) emit(_last!); // restore UI
    }
  }

  Future<void> approvePayment(String paymentId) async {
    emit(LoanDetailActionLoading());
    try {
      await _repo.approvePayment(paymentId, lenderName: _last?.loan.lenderName ?? 'Lender');
      emit(LoanDetailActionSuccess('Payment approved!'));
      await load();
    } catch (e) {
      emit(LoanDetailActionError(e.toString()));
      if (_last != null) emit(_last!); // restore UI
    }
  }

  Future<void> deleteLoan() async {
    emit(LoanDetailActionLoading());
    try {
      await _repo.deleteLoan(loanId);
      emit(LoanDetailDeleted());
    } catch (e) {
      emit(LoanDetailActionError(e.toString()));
      if (_last != null) emit(_last!);
    }
  }

  Future<void> rejectPayment(String paymentId, String reason) async {
    emit(LoanDetailActionLoading());
    try {
      await _repo.rejectPayment(paymentId, reason, lenderName: _last?.loan.lenderName ?? 'Lender');
      emit(LoanDetailActionSuccess('Payment rejected.'));
      await load();
    } catch (e) {
      emit(LoanDetailActionError(e.toString()));
      if (_last != null) emit(_last!); // restore UI
    }
  }
}
