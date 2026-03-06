import '../../../models/notification_model.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationError extends NotificationState {
  final String msg;
  NotificationError(this.msg);
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  NotificationLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationLoaded withUpdated(NotificationModel updated) {
    final list = notifications
        .map((n) => n.id == updated.id ? updated : n)
        .toList();
    return NotificationLoaded(list);
  }

  NotificationLoaded withPrepended(NotificationModel newNotif) {
    return NotificationLoaded([newNotif, ...notifications]);
  }

  NotificationLoaded allMarkedRead() {
    return NotificationLoaded(
      notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}
