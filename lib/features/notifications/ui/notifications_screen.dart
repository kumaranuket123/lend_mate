import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/notification_cubit.dart';
import '../bloc/notification_state.dart';
import '../data/notification_repository.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationCubit(NotificationRepository())..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            builder: (ctx, state) {
              if (state is! NotificationLoaded) return const SizedBox.shrink();
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => ctx.read<NotificationCubit>().markAllRead(),
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (ctx, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.msg),
                  TextButton(
                    onPressed: () =>
                        ctx.read<NotificationCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state as NotificationLoaded;

          if (loaded.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ctx.read<NotificationCubit>().load(),
            child: ListView.separated(
              itemCount: loaded.notifications.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
              itemBuilder: (_, i) {
                final n = loaded.notifications[i];
                return NotificationTile(
                  notification: n,
                  onTap: () async {
                    // Mark as read
                    if (!n.isRead) {
                      ctx.read<NotificationCubit>().markRead(n.id);
                    }
                    // Navigate to loan detail if loan_id is present
                    if (n.loanId != null) {
                      await context.push('/loan/${n.loanId}');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
