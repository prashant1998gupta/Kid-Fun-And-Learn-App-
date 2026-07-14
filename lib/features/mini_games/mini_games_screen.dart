import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/openmoji_view.dart';
import '../profiles/profiles_controller.dart';
import 'data/mini_pet.dart';
import 'data/mini_game_story.dart';
import 'data/mini_games_repository.dart';
import 'data/learning_world_item.dart';
import 'mini_games_controller.dart';

enum _MiniGameFilter {
  all('All'),
  learning('My Learning'),
  justFun('Just Fun');

  const _MiniGameFilter(this.label);
  final String label;
}

/// Connected mini-game world with a daily trail and age-friendly discovery.
class MiniGamesScreen extends ConsumerStatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  ConsumerState<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends ConsumerState<MiniGamesScreen> {
  _MiniGameFilter _filter = _MiniGameFilter.all;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(miniGamesControllerProvider);
    final visibleGames = _gamesForFilter(_filter);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _topBar(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: _PetCard(pet: gameState.pet)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _DailyChallengeCard(challenge: gameState.dailyChallenge),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _AdventureTrailCard(
                  trail: gameState.adventureTrail,
                  onPlay: (id) => _playStoryChapter(context, id),
                  onChoosePath: _chooseStoryPath,
                  onSurprise: () => _playStoryChapter(
                    context,
                    _surpriseGame(gameState),
                  ),
                ),
              ),
              if (gameState.learningWorldItems.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: _LearningWorldStrip(
                    itemIds: gameState.learningWorldItems,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: _GameFilterBar(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.crossAxisExtent < 360;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: compact ? 190 : 220,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: compact ? 0.62 : 0.66,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final game = visibleGames[index];
                          return _GameCard(
                            game: game,
                            index: index,
                            highScore: gameState.highScores[game.id] ?? 0,
                            learningLevel: gameState.learningLevels[game.id],
                            onTap: () => _openGame(context, game.id),
                          );
                        },
                        childCount: visibleGames.length,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _AchievementStrip(unlocked: gameState.achievements),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MiniGameDef> _gamesForFilter(_MiniGameFilter filter) {
    final child = ref.read(activeChildProvider);
    return kMiniGames.where((game) {
      final allowed = child == null || game.supportsGrade(child.grade);
      if (!allowed) return false;
      return switch (filter) {
        _MiniGameFilter.all => true,
        _MiniGameFilter.learning => game.learning,
        _MiniGameFilter.justFun => !game.learning,
      };
    }).toList();
  }

  String _surpriseGame(MiniGamesState state) {
    final trailNext = state.adventureTrail.nextGameId;
    if (trailNext != null) return trailNext;
    for (final game in kMiniGames) {
      if (!state.playedGames.contains(game.id)) return game.id;
    }
    return state.dailyChallenge.gameId;
  }

  Future<void> _chooseStoryPath(MiniGameStoryPath path) async {
    await ref
        .read(miniGamesControllerProvider.notifier)
        .chooseStoryPath(path.id);
    if (!mounted) return;
    final trail = ref.read(miniGamesControllerProvider).adventureTrail;
    AudioService.instance.speak(
      '${path.label} path chosen! ${trail.storyWorld.intro}',
    );
  }

  void _playStoryChapter(BuildContext context, String gameId) {
    final trail = ref.read(miniGamesControllerProvider).adventureTrail;
    final chapter = trail.gameIds.indexOf(gameId);
    if (chapter >= 0 && trail.storyPath == null) {
      AudioService.instance.speak(
        'First choose your story power: brave, kind, or curious.',
      );
      return;
    }
    if (chapter >= 0) {
      AudioService.instance.speak(
        trail.storyWorld.chapterLine(
          chapter,
          _miniGameById(gameId).name,
          trail.storyPath!,
        ),
      );
    }
    _openGame(context, gameId);
  }

  Widget _topBar(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    final coOp = child?.siblingCoopEnabled ?? false;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Row(
            children: [
              BouncyButton(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: EdgeInsets.all(compact ? 7 : 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: const Color(0xFF6C5CE7),
                    size: compact ? 22 : 24,
                  ),
                ),
              ),
              SizedBox(width: compact ? 7 : 10),
              Expanded(
                child: Text(
                  '🎮 Mini Games',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 21 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BouncyButton(
                onTap: child == null
                    ? null
                    : () async {
                        await ref
                            .read(profilesControllerProvider.notifier)
                            .setSiblingCoop(!coOp);
                        AudioService.instance.speak(!coOp
                            ? 'Team mode on! Take turns and help each other.'
                            : 'Solo mode on! Spark will be your teammate.');
                      },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 7 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: coOp
                        ? const Color(0xFFFFD166)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.group_rounded,
                        color: coOp
                            ? const Color(0xFF6C5CE7)
                            : AppColors.lightTextSoft,
                        size: compact ? 19 : 21,
                      ),
                      if (constraints.maxWidth >= 380) ...[
                        const SizedBox(width: 4),
                        Text(
                          coOp ? 'TEAM' : 'SOLO',
                          style: const TextStyle(
                            color: AppColors.lightText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      'fraction-cafe' => AppRoutes.fractionCafe,
      'multiplication-kingdom' => AppRoutes.multiplicationKingdom,
      'grammar-detective' => AppRoutes.grammarDetective,
      'code-the-robot' => AppRoutes.codeTheRobot,
      'science-machine-lab' => AppRoutes.scienceMachineLab,
      'map-quest' => AppRoutes.mapQuest,
      'eco-city-builder' => AppRoutes.ecoCityBuilder,
      'space-mission-control' => AppRoutes.spaceMissionControl,
      'business-bazaar' => AppRoutes.businessBazaar,
      'mystery-science-lab' => AppRoutes.mysteryScienceLab,
      'news-detective' => AppRoutes.newsDetective,
      'algorithm-quest' => AppRoutes.algorithmQuest,
      'infinity-loop' => AppRoutes.infinityLoop,
      '368-chickens' => AppRoutes.chickenTap,
      'stack-merge' => AppRoutes.stackMerge,
      '2048' => AppRoutes.classic2048,
      _ => AppRoutes.miniGames,
    };
    context.push(route);
  }
}

class _AdventureTrailCard extends StatelessWidget {
  const _AdventureTrailCard({
    required this.trail,
    required this.onPlay,
    required this.onChoosePath,
    required this.onSurprise,
  });

  final MiniGameAdventureTrail trail;
  final ValueChanged<String> onPlay;
  final ValueChanged<MiniGameStoryPath> onChoosePath;
  final VoidCallback onSurprise;

  @override
  Widget build(BuildContext context) {
    final path = trail.storyPath;
    final currentId = trail.nextGameId;
    final currentChapter =
        currentId == null ? 2 : trail.gameIds.indexOf(currentId);
    final narration = trail.completed
        ? trail.storyWorld.finaleFor(path ?? kMiniGameStoryPaths.last)
        : path == null
            ? trail.storyWorld.intro
            : trail.storyWorld.chapterLine(
                currentChapter,
                _miniGameById(currentId!).name,
                path,
              );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4737A8), Color(0xFF8A4DCE)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x442E207A),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trail.storyWorld.icon} ${trail.storyWorld.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              BouncyButton(
                borderRadius: BorderRadius.circular(99),
                onTap: () => AudioService.instance.speak(narration),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Semantics(
                label: '${trail.chestsWon} trail chests collected',
                child: Text(
                  '🎁 ${trail.chestsWon}',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              narration,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (path == null) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Text(
                    'Choose your power:',
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                for (final storyPath in kMiniGameStoryPaths)
                  BouncyButton(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChoosePath(storyPath),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${storyPath.icon} ${storyPath.label}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4737A8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${path.icon} ${path.label} ending',
                  style: const TextStyle(
                    color: Color(0xFF3B2A78),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              for (var index = 0; index < trail.gameIds.length; index++) ...[
                if (index > 0)
                  Container(
                    width: 13,
                    height: 4,
                    decoration: BoxDecoration(
                      color: trail.completedGameIds
                              .contains(trail.gameIds[index - 1])
                          ? const Color(0xFFFFE082)
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Expanded(
                  child: _TrailStop(
                    number: index + 1,
                    game: _miniGameById(trail.gameIds[index]),
                    complete:
                        trail.completedGameIds.contains(trail.gameIds[index]),
                    current: trail.nextGameId == trail.gameIds[index],
                    onTap: () => onPlay(trail.gameIds[index]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  trail.completed
                      ? '+15 coins • +20 XP • come back tomorrow'
                      : '${trail.progress}/3 stamps • finish all for a bonus chest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BouncyButton(
                borderRadius: BorderRadius.circular(999),
                onTap: onSurprise,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE082),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trail.completed ? 'Surprise Me 🎲' : 'Play Next ▶',
                    style: const TextStyle(
                      color: Color(0xFF3B2A78),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrailStop extends StatelessWidget {
  const _TrailStop({
    required this.number,
    required this.game,
    required this.complete,
    required this.current,
    required this.onTap,
  });

  final int number;
  final MiniGameDef game;
  final bool complete;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: complete
          ? 'Trail stop $number, ${game.name}, complete'
          : 'Trail stop $number, ${game.name}',
      child: BouncyButton(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color:
                current ? Colors.white : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: complete
                  ? const Color(0xFFFFE082)
                  : current
                      ? Colors.white
                      : Colors.white24,
              width: complete || current ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  OpenMojiView(
                    emoji: game.icon,
                    size: 29,
                    fallback:
                        Text(game.icon, style: const TextStyle(fontSize: 25)),
                  ),
                  if (complete)
                    const Positioned(
                      right: -7,
                      top: -7,
                      child: Text('✅', style: TextStyle(fontSize: 14)),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                game.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: current ? const Color(0xFF3B2A78) : Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameFilterBar extends StatelessWidget {
  const _GameFilterBar({required this.selected, required this.onSelected});

  final _MiniGameFilter selected;
  final ValueChanged<_MiniGameFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _MiniGameFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final filter = _MiniGameFilter.values[index];
          final active = filter == selected;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(filter.label),
            onSelected: (_) => onSelected(filter),
            selectedColor: const Color(0xFFFFE082),
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: active ? const Color(0xFF4737A8) : const Color(0xFF4A3B52),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

MiniGameDef _miniGameById(String id) =>
    kMiniGames.firstWhere((game) => game.id == id);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 14,
            vertical: compact ? 9 : 10,
          ),
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
                  style: TextStyle(fontSize: compact ? 32 : 38),
                ),
              ),
              SizedBox(width: compact ? 9 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet.name} • ${pet.xp} pet stars',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF4A3B52),
                        fontSize: compact ? 13.5 : 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: pet.isMax ? 1 : pet.progress,
                      minHeight: compact ? 8 : 9,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF725B7A),
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final DailyMiniGameChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final progress = (challenge.progress / challenge.target).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(
                challenge.completed ? '🏆' : '⭐',
                style: TextStyle(fontSize: compact ? 26 : 30),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.completed
                          ? 'Daily challenge complete!'
                          : challenge.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2D3436),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: compact ? 6 : 7,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: const Color(0xFFE8E5FF),
                      color: const Color(0xFF6C5CE7),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                '${challenge.progress.clamp(0, challenge.target)}/'
                '${challenge.target}',
                style: TextStyle(
                  color: const Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],
          ),
        );
      },
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

    final card = LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < 165 || constraints.maxHeight < 245;
        final iconSize = tight ? 38.0 : 46.0;
        return Container(
          padding: EdgeInsets.all(tight ? 9 : 12),
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
                blurRadius: tight ? 12 : 18,
                offset: Offset(0, tight ? 5 : 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon nestled in a soft glossy bubble so the illustration pops.
              Container(
                padding: EdgeInsets.all(tight ? 9 : 12),
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
                  size: iconSize,
                  fallback: Text(
                    game.icon,
                    style: TextStyle(fontSize: tight ? 34 : 40),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                  begin: 0,
                  end: tight ? -3 : -5,
                  duration: 1600.ms,
                  curve: Curves.easeInOut),
              SizedBox(height: tight ? 7 : 10),
              Text(
                game.name,
                maxLines: tight ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tight ? 14.5 : 17,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                game.description,
                maxLines: tight ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: tight ? 10.5 : 11.5,
                  height: 1.12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tight ? 7 : 10),
              // Status pill: bright when solved, soft "Play!" otherwise.
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tight ? 10 : 14,
                  vertical: tight ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tight ? 11.5 : 13,
                    fontWeight: FontWeight.w900,
                    color: deep,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return BouncyButton(
      borderRadius: AppSpacing.cardRadius,
      onTap: onTap,
      child: card,
    )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
