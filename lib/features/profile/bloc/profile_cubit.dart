import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repo;

  ProfileCubit(this._repo) : super(ProfileInitial());

  Future<void> load() async {
    emit(ProfileLoading());
    try {
      final profileFuture = _repo.fetchProfile();
      final statsFuture   = _repo.fetchStats();
      final profile = await profileFuture;
      final stats   = await statsFuture;
      emit(ProfileLoaded(
        profile:    profile,
        totalLent:  (stats['totalLent'] as num).toDouble(),
        totalBorr:  (stats['totalBorr'] as num).toDouble(),
        activeLoans: stats['activeLoans'] as int,
        closedLoans: stats['closedLoans'] as int,
        totalLoans:  stats['totalLoans'] as int,
      ));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateName(String name) async {
    final cur = state;
    if (cur is! ProfileLoaded) return;
    emit(ProfileUpdating());
    try {
      final updated = await _repo.updateName(name);
      emit(cur.copyWithProfile(updated));
      emit(ProfileUpdateSuccess('Name updated'));
      emit(cur.copyWithProfile(updated)); // restore loaded after success flash
    } catch (e) {
      emit(ProfileUpdateError(e.toString()));
      emit(cur); // restore previous loaded state
    }
  }

  Future<void> uploadAvatar(File file) async {
    final cur = state;
    if (cur is! ProfileLoaded) return;
    emit(ProfileUpdating());
    try {
      final url     = await _repo.uploadAvatar(file);
      final updated = cur.profile.copyWith(avatarUrl: url);
      emit(cur.copyWithProfile(updated));
      emit(ProfileUpdateSuccess('Avatar updated'));
      emit(cur.copyWithProfile(updated));
    } catch (e) {
      emit(ProfileUpdateError(e.toString()));
      emit(cur);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}
