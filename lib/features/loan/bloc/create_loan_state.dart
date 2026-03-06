import '../../../models/profile_model.dart';

abstract class CreateLoanState {}

class CreateLoanInitial extends CreateLoanState {}

class CreateLoanLoading extends CreateLoanState {}

class CreateLoanSuccess extends CreateLoanState {}

class CreateLoanError extends CreateLoanState {
  final String msg;
  CreateLoanError(this.msg);
}

class BorrowerSearchLoading extends CreateLoanState {}

class BorrowerSearchResult extends CreateLoanState {
  final List<ProfileModel> results;
  BorrowerSearchResult(this.results);
}
