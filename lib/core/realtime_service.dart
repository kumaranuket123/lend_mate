import 'dart:async';
import '../core/supabase_client.dart';

/// Lightweight service that exposes a stream of unread notification counts
/// for the currently authenticated user.  Used by the home AppBar badge.
class RealtimeService {
  final String _uid = supabase.auth.currentUser!.id;

  StreamController<int>? _controller;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  Stream<int> unreadCountStream() {
    _controller = StreamController<int>.broadcast(
      onListen:  _start,
      onCancel:  _stop,
    );
    return _controller!.stream;
  }

  void _start() {
    _sub = supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _uid)
        .listen(
          (rows) {
            final count = rows.where((r) => r['is_read'] == false).length;
            if (!(_controller?.isClosed ?? true)) {
              _controller!.add(count);
            }
          },
          // Swallow realtime timeout / network errors — badge just won't
          // update until the next successful push, which is acceptable.
          onError: (_) {},
        );
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() {
    _stop();
    _controller?.close();
  }
}
