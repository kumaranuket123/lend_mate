import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/loan_repository.dart';
import 'create_loan_state.dart';

class CreateLoanCubit extends Cubit<CreateLoanState> {
  final LoanRepository _repo;
  CreateLoanCubit(this._repo) : super(CreateLoanInitial());

  Future<void> searchBorrowers(String q) async {
    if (q.trim().length < 2) return;
    emit(BorrowerSearchLoading());
    try {
      final res = await _repo.searchUsers(q);
      emit(BorrowerSearchResult(res));
    } catch (e) {
      emit(CreateLoanError(e.toString()));
    }
  }

  Future<void> createLoan({
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
    emit(CreateLoanLoading());
    try {
      await _repo.createLoan(
        borrowerId:         borrowerId,
        amount:             amount,
        interestRate:       interestRate,
        tenureMonths:       tenureMonths,
        startDate:          startDate,
        emiDate:            emiDate,
        lenderUpi:          lenderUpi,
        borrowerUpi:        borrowerUpi,
        notes:              notes,
        modeOnExtraPayment: modeOnExtraPayment,
      );
      emit(CreateLoanSuccess());
    } catch (e) {
      emit(CreateLoanError(e.toString()));
    }
  }
}
