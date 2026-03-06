import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../data/profile_repository.dart';
import 'widgets/avatar_picker.dart';
import 'widgets/profile_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(ProfileRepository())..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (ctx, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is ProfileUpdateError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.msg),
                backgroundColor: cs.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(state.msg),
                  TextButton(
                    onPressed: () => ctx.read<ProfileCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Also show loaded UI while updating (show spinner overlay)
          final isUpdating = state is ProfileUpdating;
          final loaded = isUpdating
              ? null
              : (state is ProfileLoaded ? state : null);

          // If updating, show a full-screen loader on top
          if (isUpdating) {
            return const Center(child: CircularProgressIndicator());
          }

          if (loaded == null) return const SizedBox.shrink();

          return _ProfileBody(loaded: loaded);
        },
      ),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  final ProfileLoaded loaded;
  const _ProfileBody({required this.loaded});

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.loaded.profile.name);
  }

  @override
  void didUpdateWidget(_ProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaded.profile.name != widget.loaded.profile.name) {
      _nameCtrl.text = widget.loaded.profile.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs   = Theme.of(context).colorScheme;
    final tt   = Theme.of(context).textTheme;
    final fmt  = NumberFormat('#,##,##0', 'en_IN');
    final cubit = context.read<ProfileCubit>();
    final p    = widget.loaded.profile;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        // ── Avatar + Name ────────────────────────────
        Center(
          child: Column(
            children: [
              AvatarPicker(
                avatarUrl: p.avatarUrl,
                initials:  p.name,
                onPicked:  (file) => cubit.uploadAvatar(file),
              ),
              const SizedBox(height: 16),
              Text(
                p.name,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                p.email ?? '',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Edit Name ────────────────────────────────
        Text(
          'Display Name',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                hintText: 'Your name',
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              cubit.updateName(name);
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ]),

        const SizedBox(height: 32),

        // ── Stats grid ───────────────────────────────
        Text(
          'Your Activity',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            ProfileStatCard(
              label: 'Total Lent',
              value: '₹${fmt.format(widget.loaded.totalLent)}',
              icon:  Icons.trending_up_rounded,
              color: Colors.green,
            ),
            ProfileStatCard(
              label: 'Total Borrowed',
              value: '₹${fmt.format(widget.loaded.totalBorr)}',
              icon:  Icons.trending_down_rounded,
              color: cs.primary,
            ),
            ProfileStatCard(
              label: 'Active Loans',
              value: '${widget.loaded.activeLoans}',
              icon:  Icons.account_balance_wallet_outlined,
              color: Colors.orange,
            ),
            ProfileStatCard(
              label: 'Closed Loans',
              value: '${widget.loaded.closedLoans}',
              icon:  Icons.check_circle_outline,
              color: cs.secondary,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── Sign out ─────────────────────────────────
        OutlinedButton.icon(
          onPressed: () async {
            await cubit.signOut();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: cs.error,
            side: BorderSide(color: cs.error.withOpacity(0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
