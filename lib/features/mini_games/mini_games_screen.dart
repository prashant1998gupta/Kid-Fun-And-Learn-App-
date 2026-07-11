import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/openmoji_view.dart';
import 'data/mini_pet.dart';
import 'data/mini_games_repository.dart';
import 'data/learning_world_item.dart';
import 'mini_games_controller.dart';

/// Grid listing of all available mini games.
class MiniGamesScreen extends ConsumerWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(miniGamesControllerProvider);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const SizedBox(height: 8),
              _PetCard(pet: gameState.pet),
              const SizedBox(height: 8),
              _DailyChallengeCard(challenge: gameState.dailyChallenge),
              if (gameState.learningWorldItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                _LearningWorldStrip(itemIds: gameState.learningWorldItems),
              ],
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
                        index: index,
                        highScore: gameState.highScores[game.id] ?? 0,
                        learningLevel: gameState.learningLevels[game.id],
                        onTap: () => _openGame(context, game.id),
                      );
                    },
                  ),
                ),
              ),
              _AchievementStrip(unlocked: gameState.achievements),
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
      'toy-sort' => AppRoutes.toySort,
      'feed-the-pet' => AppRoutes.feedThePet,
      'sound-safari' => AppRoutes.soundSafari,
      'number-garden' => AppRoutes.numberGarden,
      'story-train' => AppRoutes.storyTrain,
      'letter-bakery' => AppRoutes.letterBakery,
      'clean-room-helper' => AppRoutes.cleanRoomHelper,
      'math-market' => AppRoutes.mathMarket,
      'word-wizard-workshop' => AppRoutes.wordWizard,
      'sentence-train' => AppRoutes.sentenceTrain,
      'clock-adventure' => AppRoutes.clockAdventure,
      'nature-detective' => AppRoutes.natureDetective,
      'shape-builder' => AppRoutes.shapeBuilder,
      'infinity-loop' => AppRoutes.infinityLoop,
      '368-chickens' => AppRoutes.chickenTap,
      'stack-merge' => AppRoutes.stackMerge,
      '2048' => AppRoutes.classic2048,
      _ => AppRoutes.miniGames,
    };
    context.push(route);
  }
}

class _LearningWorldStrip extends StatelessWidget {
  const _LearningWorldStrip({required this.itemIds});

  final Set<String> itemIds;

  @override
  Widget build(BuildContext context) {
    final items = itemIds
        .map(LearningWorldCatalog.byId)
        .whereType<LearningWorldItem>()
        .toList();
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.park_rounded, color: Color(0xFF00A878)),
          const SizedBox(width: 7),
          const Text(
            'My World',
            style: TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (_, index) => Tooltip(
                message: items[index].name,
                child: Center(
                  child: Text(
                    items[index].emoji,
                    style: const TextStyle(fontSize: 29),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final MiniPet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7D6), Color(0xFFFFE4F2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: '${pet.name} wearing ${pet.accessory}',
            child: Text(
              '${pet.emoji}${pet.accessory}',
              style: const TextStyle(fontSize: 38),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.name} • ${pet.xp} pet stars',
                  style: const TextStyle(
                    color: Color(0xFF4A3B52),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: pet.isMax ? 1 : pet.progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: Colors.white,
                  color: const Color(0xFFFF8AB3),
                ),
                const SizedBox(height: 3),
                Text(
                  pet.isMax
                      ? 'Your pet is fully grown! ✨'
                      : '${pet.xpToNext} stars to grow • '
                          '${pet.unlockedAccessories.join(' ')}',
                  style: const TextStyle(
                    color: Color(0xFF725B7A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final DailyMiniGameChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final progress = (challenge.progress / challenge.target).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(challenge.completed ? '🏆' : '⭐',
              style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.completed
                      ? 'Daily challenge complete!'
                      : challenge.title,
                  style: const TextStyle(
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: const Color(0xFFE8E5FF),
                  color: const Color(0xFF6C5CE7),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${challenge.progress.clamp(0, challenge.target)}/'
            '${challenge.target}',
            style: const TextStyle(
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementStrip extends StatelessWidget {
  const _AchievementStrip({required this.unlocked});

  final Set<String> unlocked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        scrollDirection: Axis.horizontal,
        itemCount: kMiniGameAchievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final badge = kMiniGameAchievements[index];
          final earned = unlocked.contains(badge.id);
          return Tooltip(
            message: '${badge.title}: ${badge.description}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: earned
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(earned ? badge.icon : '🔒'),
                  const SizedBox(width: 5),
                  Text(
                    badge.title,
                    style: TextStyle(
                      color: earned ? const Color(0xFF2D3436) : Colors.white70,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.index,
    required this.highScore,
    required this.learningLevel,
    required this.onTap,
  });

  final MiniGameDef game;
  final int index;
  final int highScore;
  final int? learningLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = Color(game.color);
    // A darker sibling of the game's own hue gives each tile depth + identity,
    // so cards pop off the pastel background instead of washing out.
    final deep = Color.lerp(base, Colors.black, 0.22)!;
    final solved = highScore > 0;
    final status = game.learning
        ? game.gradeBand == null
            ? 'Level ${learningLevel ?? 1}/50'
            : '${game.gradeBand} • L${learningLevel ?? 1}'
        : solved
            ? (game.id == 'infinity-loop' ? '✓ Solved' : '🏆 $highScore')
            : 'Play!';

    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, deep],
          ),
          borderRadius: AppSpacing.cardRadius,
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon nestled in a soft glossy bubble so the illustration pops.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: OpenMojiView(
                emoji: game.icon,
                size: 46,
                fallback: Text(game.icon, style: const TextStyle(fontSize: 40)),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                begin: 0, end: -5, duration: 1600.ms, curve: Curves.easeInOut),
            const SizedBox(height: 10),
            Text(
              game.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              game.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.15,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Status pill: bright when solved, soft "Play!" otherwise.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: deep,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
