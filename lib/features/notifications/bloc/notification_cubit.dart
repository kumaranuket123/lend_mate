import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/notification_model.dart';
import '../data/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repo;
  StreamSubscription<NotificationModel>? _sub;

  NotificationCubit(this._repo) : super(NotificationInitial());

  Future<void> load() async {
    emit(NotificationLoading());
    try {
      final list = await _repo.fetchAll();
      emit(NotificationLoaded(list));
      _subscribeRealtime();
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void _subscribeRealtime() {
    _sub?.cancel();
    _sub = _repo.realtimeStream().listen(
      (newNotif) {
        final cur = state;
        if (cur is NotificationLoaded) {
          final exists = cur.notifications.any((n) => n.id == newNotif.id);
          if (!exists) emit(cur.withPrepended(newNotif));
        }
      },
      // Realtime can timeout on first connect or with poor network.
      // The list was already loaded via fetchAll(); realtime is best-effort.
      onError: (_) {},
    );
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    final cur = state;
    if (cur is NotificationLoaded) {
      final updated = cur.notifications
          .firstWhere((n) => n.id == id)
          .copyWith(isRead: true);
      emit(cur.withUpdated(updated));
    }
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    final cur = state;
    if (cur is NotificationLoaded) emit(cur.allMarkedRead());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
