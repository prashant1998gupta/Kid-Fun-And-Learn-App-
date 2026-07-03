import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/openmoji_view.dart';
import 'data/mini_games_repository.dart';
import 'mini_games_controller.dart';

/// Grid listing of all available mini games.
class MiniGamesScreen extends ConsumerWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highScores = ref.watch(miniGamesControllerProvider);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: kMiniGames.length,
                    itemBuilder: (context, index) {
                      final game = kMiniGames[index];
                      return _GameCard(
                        game: game,
                        highScore: highScores[game.id] ?? 0,
                        onTap: () => _openGame(context, game.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF6C5CE7), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '🎮 Mini Games',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _openGame(BuildContext context, String id) {
    final route = switch (id) {
      'infinity-loop' => AppRoutes.infinityLoop,
      '368-chickens' => AppRoutes.chickenTap,
      'stack-merge' => AppRoutes.stackMerge,
      '2048' => AppRoutes.classic2048,
      _ => AppRoutes.miniGames,
    };
    context.push(route);
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.highScore,
    required this.onTap,
  });

  final MiniGameDef game;
  final int highScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Color(game.color).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OpenMojiView(
              emoji: game.icon,
              size: 56,
              fallback: Text(game.icon, style: const TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 8),
            Text(
              game.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              game.description,
              style: TextStyle(
                fontSize: 12,
                color: Color(game.color).withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              highScore > 0
                  ? game.id == 'infinity-loop'
                      ? '✓ Solved'
                      : '🏆 Best: $highScore'
                  : 'Play!',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C5CE7)),
            ),
          ],
        ),
      ),
    );
  }
}
