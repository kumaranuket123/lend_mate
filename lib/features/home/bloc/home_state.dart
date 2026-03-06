import '../../../models/loan_model.dart';
import '../../../models/profile_model.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String msg;
  HomeError(this.msg);
}

class HomeLoaded extends HomeState {
  final ProfileModel profile;
  final List<LoanModel> lentLoans;
  final List<LoanModel> borrowedLoans;

  HomeLoaded({
    required this.profile,
    required this.lentLoans,
    required this.borrowedLoans,
  });

  double get totalLent => lentLoans.fold(0, (s, l) => s + l.amount);
  double get totalBorrowed => borrowedLoans.fold(0, (s, l) => s + l.amount);
  double get lentOutstanding =>
      lentLoans.fold(0, (s, l) => s + l.remainingPrincipal);
  double get borrowedOutstanding =>
      borrowedLoans.fold(0, (s, l) => s + l.remainingPrincipal);
}
