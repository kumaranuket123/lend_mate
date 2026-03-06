import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/home_cubit.dart';
import '../bloc/home_state.dart';
import '../data/home_repository.dart';
import '../../../core/realtime_service.dart';
import 'loan_card.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(HomeRepository())..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _realtimeService = RealtimeService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _realtimeService.unreadCountStream().listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _realtimeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Icon(Icons.handshake_rounded, color: cs.primary, size: 24),
            const SizedBox(width: 8),
            Text('LendMate',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                )),
          ],
        ),
        actions: [
          // Notification bell
          IconButton(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text('$_unreadCount'),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            onPressed: () async {
              await context.push('/notifications');
              // reset badge optimistically (stream will update again)
            },
          ),
          // Profile avatar
          BlocBuilder<HomeCubit, HomeState>(
            builder: (_, state) {
              final name = state is HomeLoaded ? state.profile.name : '';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Loans Lent'),
            Tab(text: 'Loans Borrowed'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),

      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (ctx, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.msg),
                  TextButton(
                    onPressed: () => ctx.read<HomeCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final loaded = state as HomeLoaded;

          return TabBarView(
            controller: _tabs,
            children: [
              // ── Dashboard ──
              RefreshIndicator(
                onRefresh: () => ctx.read<HomeCubit>().load(),
                child: DashboardTab(state: loaded),
              ),

              // ── Loans Lent ──
              RefreshIndicator(
                onRefresh: () => ctx.read<HomeCubit>().load(),
                child: loaded.lentLoans.isEmpty
                    ? _EmptyLoans(
                        message: "You haven't lent any money yet",
                        icon: Icons.trending_up_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: loaded.lentLoans.length,
                        itemBuilder: (_, i) => LoanCard(
                          loan: loaded.lentLoans[i],
                          isLender: true,
                          onTap: () async {
                            final result = await context.push('/loan/${loaded.lentLoans[i].id}');
                            if (result == true && ctx.mounted) ctx.read<HomeCubit>().load();
                          },
                        ),
                      ),
              ),

              // ── Loans Borrowed ──
              RefreshIndicator(
                onRefresh: () => ctx.read<HomeCubit>().load(),
                child: loaded.borrowedLoans.isEmpty
                    ? _EmptyLoans(
                        message: "You haven't borrowed any money yet",
                        icon: Icons.trending_down_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: loaded.borrowedLoans.length,
                        itemBuilder: (_, i) => LoanCard(
                          loan: loaded.borrowedLoans[i],
                          isLender: false,
                          onTap: () async {
                            final result = await context.push('/loan/${loaded.borrowedLoans[i].id}');
                            if (result == true && ctx.mounted) ctx.read<HomeCubit>().load();
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),

      // FAB: Create new loan
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push('/create-loan');
          if (created == true && context.mounted) {
            context.read<HomeCubit>().load();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Loan'),
      ),
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyLoans({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(message,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Tap + New Loan to get started',
              style: tt.labelSmall?.copyWith(color: cs.outlineVariant)),
        ],
      ),
    );
  }
}
