import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../auth/auth_controller.dart';
import '../profiles/widgets/avatar_view.dart';
import 'domain/leaderboard_entry.dart';
import 'leaderboard_controller.dart';

/// Friends leaderboard: a group of families sharing a code compete on weekly
/// stars. Non-PII (display name + illustrated avatar + score only). Entries are
/// written server-side; this screen reads and renders them, with graceful
/// states for offline / signed-out / no-group.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    // Push our latest score when arriving with a group already joined.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardControllerProvider.notifier).publish();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final code = ref.watch(leaderboardControllerProvider);

    Widget body;
    if (!auth.cloudEnabled) {
      body = const _Info(
        icon: Icons.cloud_off_rounded,
        title: 'Play with friends online',
        message:
            'Friends leaderboards need a cloud account. This build is offline, '
            'so keep collecting stars — they still count!',
      );
    } else if (auth.status != AuthStatus.signedIn) {
      body = _Info(
        icon: Icons.login_rounded,
        title: 'Sign in to join friends',
        message: 'A parent can sign in to create or join a friends group.',
        action: FilledButton(
          onPressed: () => context.push(AppRoutes.signIn),
          child: const Text('Sign in'),
        ),
      );
    } else if (code == null || code.isEmpty) {
      body = const _JoinGroup();
    } else {
      body = _Board(code: code);
    }

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.space,
        child: SafeArea(
          child: Column(
            children: [
              _Header(code: code),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.code});
  final String? code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Friends',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          if ((code ?? '').isNotEmpty)
            BouncyButton(
              onTap: () =>
                  ref.read(leaderboardControllerProvider.notifier).leaveGroup(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(AppSpacing.radiusPill),
                ),
                child: const Text('Leave',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

class _JoinGroup extends ConsumerStatefulWidget {
  const _JoinGroup();
  @override
  ConsumerState<_JoinGroup> createState() => _JoinGroupState();
}

class _JoinGroupState extends ConsumerState<_JoinGroup> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 12),
            Text(
              'Join a Friends Group',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a code your friend shared — or make up a new one and share '
              'it. Everyone with the same code competes on weekly stars!',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'e.g. STARS7',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(leaderboardControllerProvider.notifier)
                  .joinGroup(_controller.text),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text('Join / Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  const _Board({required this.code});
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authControllerProvider).account?.uid;
    final entriesAsync = ref.watch(leaderboardEntriesProvider(code));

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _Info(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load the board',
        message: 'Check your connection and try again.',
      ),
      data: (raw) {
        final entries = [
          for (final e in raw) e.copyWith(isMe: e.id == myUid),
        ];
        return Column(
          children: [
            _InviteBanner(code: code),
            Expanded(
              child: entries.isEmpty
                  ? const _Info(
                      icon: Icons.groups_rounded,
                      title: 'Waiting for friends…',
                      message:
                          'Share your code! Scores appear here as friends play '
                          'and earn stars this week.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => _EntryTile(entry: entries[i])
                          .animate()
                          .fadeIn(delay: (40 * i).ms)
                          .slideX(begin: 0.1, end: 0),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InviteBanner extends StatelessWidget {
  const _InviteBanner({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Group code',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          BouncyButton(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied — share it! 🎉')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.copy_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#${entry.rank}',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: entry.isMe
            ? AppColors.accent.withValues(alpha: 0.95)
            : Colors.white,
        borderRadius: AppSpacing.cardRadius,
        border: entry.isMe ? Border.all(color: Colors.white, width: 3) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              medal,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          AvatarView(config: AvatarSeed.decode(entry.avatarSeed), size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.isMe ? '${entry.displayName} (You)' : entry.displayName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const Icon(Icons.star_rounded, color: AppColors.star),
          const SizedBox(width: 4),
          Text(
            '${entry.score}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
