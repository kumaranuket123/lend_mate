import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repo;
  HomeCubit(this._repo) : super(HomeInitial());

  Future<void> load() async {
    emit(HomeLoading());
    try {
      final results = await Future.wait([
        _repo.getProfile(),
        _repo.getLentLoans(),
        _repo.getBorrowedLoans(),
      ]);
      emit(HomeLoaded(
        profile:       results[0] as dynamic,
        lentLoans:     results[1] as dynamic,
        borrowedLoans: results[2] as dynamic,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
