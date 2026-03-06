import 'package:flutter/foundation.dart';
import '../../../core/supabase_client.dart';
import '../../../models/notification_model.dart';

class NotificationRepository {
  final _uid = supabase.auth.currentUser!.id;

  Future<List<NotificationModel>> fetchAll() async {
    debugPrint('[Notifications] fetchAll →');
    final data = await supabase
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(50);
    final list = (data as List).map((m) => NotificationModel.fromMap(m)).toList();
    debugPrint('[Notifications] fetchAll ✓ count=${list.length}');
    return list;
  }

  Future<void> markRead(String notificationId) async {
    debugPrint('[Notifications] markRead → id=$notificationId');
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
    debugPrint('[Notifications] markRead ✓');
  }

  Future<void> markAllRead() async {
    debugPrint('[Notifications] markAllRead →');
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
    debugPrint('[Notifications] markAllRead ✓');
  }

  Future<int> unreadCount() async {
    debugPrint('[Notifications] unreadCount →');
    final res = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', _uid)
        .eq('is_read', false);
    final count = (res as List).length;
    debugPrint('[Notifications] unreadCount ✓ count=$count');
    return count;
  }

  /// Realtime stream of new notifications for the current user
  Stream<NotificationModel> realtimeStream() {
    return supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(1)
        .map((rows) =>
            rows.isNotEmpty ? NotificationModel.fromMap(rows.first) : null)
        .where((n) => n != null)
        .cast<NotificationModel>();
  }
}
