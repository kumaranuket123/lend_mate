import '../../../models/profile_model.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String msg;
  ProfileError(this.msg);
}

class ProfileLoaded extends ProfileState {
  final ProfileModel profile;
  final double       totalLent;
  final double       totalBorr;
  final int          activeLoans;
  final int          closedLoans;
  final int          totalLoans;

  ProfileLoaded({
    required this.profile,
    required this.totalLent,
    required this.totalBorr,
    required this.activeLoans,
    required this.closedLoans,
    required this.totalLoans,
  });

  ProfileLoaded copyWithProfile(ProfileModel p) => ProfileLoaded(
        profile:    p,
        totalLent:  totalLent,
        totalBorr:  totalBorr,
        activeLoans: activeLoans,
        closedLoans: closedLoans,
        totalLoans:  totalLoans,
      );
}

class ProfileUpdating extends ProfileState {}

class ProfileUpdateSuccess extends ProfileState {
  final String msg;
  ProfileUpdateSuccess(this.msg);
}

class ProfileUpdateError extends ProfileState {
  final String msg;
  ProfileUpdateError(this.msg);
}
