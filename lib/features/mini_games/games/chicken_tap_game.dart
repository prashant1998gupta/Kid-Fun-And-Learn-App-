import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/openmoji_view.dart';
import '../../settings/settings_controller.dart';
import '../logic/chicken_tap_rules.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';

class ChickenTapGame extends ConsumerStatefulWidget {
  const ChickenTapGame({super.key});

  @override
  ConsumerState<ChickenTapGame> createState() => _ChickenTapGameState();
}

class _ChickenTapGameState extends ConsumerState<ChickenTapGame> {
  int _score = 0;
  int _missed = 0;
  int _combo = 0;
  int _bestCombo = 0;
  int _bonusSeconds = 0;
  int _eggsCollected = 0;
  final List<int> _playerScores = [0, 0];
  int _timeLeft = 30;
  // Dynamic difficulty: rises when the child misses (game slows + chickens live
  // longer) and falls when they catch (game tightens up). Self-balancing.
  double _struggleBoost = 0;
  bool _gameOver = false;
  bool _started = false;
  bool _paused = false;
  bool _bossSpawned = false;
  final MiniGameDifficulty _difficulty = MiniGameDifficulty.easy;
  MiniGamePlayMode _playMode = MiniGamePlayMode.solo;
  String _message = 'Tap the chickens! Just have fun!';
  final List<_ChickenTarget> _targets = [];
  final List<_TapBurst> _bursts = [];
  final math.Random _random = math.Random();
  final Stopwatch _clock = Stopwatch();
  final _celebration = CelebrationController();
  Timer? _ticker;
  Duration _nextSpawn = Duration.zero;
  int _nextId = 0;

  int get _roundSeconds => switch (_difficulty) {
        MiniGameDifficulty.easy => 35,
        MiniGameDifficulty.normal => 30,
        MiniGameDifficulty.challenge => 30,
      };
  int get _maxMisses => switch (_difficulty) {
        MiniGameDifficulty.easy => 5,
        MiniGameDifficulty.normal => 5,
        MiniGameDifficulty.challenge => 3,
      };

  /// On Easy the round is purely time-based — a child can never "lose"; they
  /// just play the clock out and collect a happy score. (Hearts are hidden.)
  bool get _noFail => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showFirstPlayTutorial(
          context,
          ref,
          gameId: '368-chickens',
          instruction: 'Tap the chickens before they run away. '
              'Grab eggs, skip the bombs!',
          emoji: '🐔',
        );
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _clock.stop();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _started = true;
      _score = 0;
      _missed = 0;
      _combo = 0;
      _bestCombo = 0;
      _bonusSeconds = 0;
      _eggsCollected = 0;
      _playerScores
        ..[0] = 0
        ..[1] = 0;
      _gameOver = false;
      _paused = false;
      _bossSpawned = false;
      _struggleBoost = 0;
      _timeLeft = _roundSeconds;
      _targets.clear();
      _bursts.clear();
      _message = 'Ready? The chickens are running!';
    });
    _clock
      ..reset()
      ..start();
    _nextSpawn = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 70), (_) => _tick());
    AudioService.instance.speak('Catch the chickens. Avoid the bombs!');
  }

  void _togglePause() {
    if (!_started || _gameOver) return;
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _clock.stop();
        _message = 'Paused. Take a breath!';
      } else {
        _clock.start();
        _message = 'Go! Catch the chickens!';
      }
    });
  }

  void _tick() {
    if (_gameOver || _paused || !mounted) return;
    final elapsed = _clock.elapsed;
    final totalSeconds = _roundSeconds + _bonusSeconds;
    final progress =
        (elapsed.inMilliseconds / (_roundSeconds * 1000)).clamp(0.0, 1.0);
    var shouldEnd = false;
    setState(() {
      _timeLeft =
          (totalSeconds - elapsed.inMilliseconds / 1000).ceil().clamp(0, 99);
      if (!_bossSpawned && progress >= 0.72) {
        _bossSpawned = true;
        _spawnTarget(elapsed, forcedType: ChickenTargetType.boss);
        _message = 'Giant golden chicken! Tap it three times!';
      } else if (elapsed >= _nextSpawn) {
        _spawnTarget(elapsed);
      }

      for (var i = _targets.length - 1; i >= 0; i--) {
        final target = _targets[i];
        if (elapsed >= target.expiresAt) {
          _targets.removeAt(i);
          if (ChickenTapRules.countsAsMiss(target.type)) {
            _missed++;
            _combo = 0;
            _struggleBoost = (_struggleBoost + 0.34).clamp(0.0, 1.0);
            _message = target.type == ChickenTargetType.boss
                ? 'The boss escaped!'
                : 'Oops, a chicken slipped away!';
          }
        }
      }
      _bursts.removeWhere(
        (burst) =>
            elapsed - burst.createdAt > const Duration(milliseconds: 650),
      );
      shouldEnd = elapsed >= Duration(seconds: totalSeconds);
    });
    if (shouldEnd) _endGame();
  }

  void _spawnTarget(
    Duration elapsed, {
    ChickenTargetType? forcedType,
  }) {
    final type = forcedType ?? _randomType();
    final progress =
        (elapsed.inMilliseconds / (_roundSeconds * 1000)).clamp(0.0, 1.0);
    final baseLifetime = switch (_difficulty) {
      MiniGameDifficulty.easy => 3400,
      MiniGameDifficulty.normal => 1900,
      MiniGameDifficulty.challenge => 1450,
    };
    // Easy stays calm the whole round; harder modes speed up over time. The
    // struggle boost lengthens lifetimes when the child is having a hard time.
    final shrink = _difficulty == MiniGameDifficulty.easy ? 250 : 650;
    final lifetime = type == ChickenTargetType.boss
        ? 4600
        : (baseLifetime - (shrink * progress) + _struggleBoost * 900).round();
    final reduced = ref.read(reducedMotionProvider);
    // Runners walk across the field and hop; bombs & the boss move slower so
    // they're easy to read. Speed grows a little as the round heats up.
    final dir = _random.nextBool() ? 1.0 : -1.0;
    final baseSpeed = 0.11 + _random.nextDouble() * 0.13 + progress * 0.10;
    final typeScale = switch (type) {
      ChickenTargetType.bomb => 0.5,
      ChickenTargetType.boss => 0.35,
      ChickenTargetType.egg => 0.7,
      _ => 1.0,
    };
    _targets.add(
      _ChickenTarget(
        id: _nextId++,
        type: type,
        baseX: _random.nextDouble() * 0.72 + 0.08,
        y: _random.nextDouble() * 0.6 + 0.06,
        size: type == ChickenTargetType.boss
            ? 82
            : 48 + _random.nextDouble() * 18,
        phase: _random.nextDouble() * math.pi * 2,
        amplitude: reduced ? 0 : (0.015 + _random.nextDouble() * 0.03),
        vx: reduced ? 0 : dir * baseSpeed * typeScale,
        hop: (reduced || type == ChickenTargetType.egg)
            ? 0
            : 0.05 + _random.nextDouble() * 0.05,
        spawnedAt: elapsed,
        expiresAt: elapsed + Duration(milliseconds: lifetime),
        hitsRemaining: type == ChickenTargetType.boss ? 3 : 1,
      ),
    );
    final baseSpawn = switch (_difficulty) {
      MiniGameDifficulty.easy => 750,
      MiniGameDifficulty.normal => 620,
      MiniGameDifficulty.challenge => 520,
    };
    final spawnSpeedup = _difficulty == MiniGameDifficulty.easy ? 120 : 260;
    _nextSpawn = elapsed +
        Duration(
          milliseconds:
              (baseSpawn - spawnSpeedup * progress + _struggleBoost * 350)
                  .round(),
        );
  }

  ChickenTargetType _randomType() {
    final roll = _random.nextInt(100);
    // Fewer bombs on Easy — they're a "don't tap" surprise, not a trap.
    final bombCap = _difficulty == MiniGameDifficulty.easy ? 3 : 7;
    if (roll < bombCap) return ChickenTargetType.bomb;
    if (roll < bombCap + 8) return ChickenTargetType.egg;
    if (roll < bombCap + 18) return ChickenTargetType.golden;
    return ChickenTargetType.chicken;
  }

  void _tapTarget(int id) {
    if (_gameOver || _paused) return;
    final index = _targets.indexWhere((target) => target.id == id);
    if (index < 0) return;
    final target = _targets[index];
    final bx = target.currentX(_clock.elapsed);
    final by = target.currentY(_clock.elapsed);
    setState(() {
      if (target.type == ChickenTargetType.bomb) {
        _bursts.add(_TapBurst(
            x: bx, y: by, createdAt: _clock.elapsed, icon: '💥'));
        _targets.removeAt(index);
        _score = math.max(0, _score + ChickenTapRules.points(target.type, 0));
        _missed++;
        _combo = 0;
        _message = 'Boom! Avoid the bombs!';
        AudioService.instance.playSfx(Sfx.wrong);
        AudioService.instance.successHaptic();
        return;
      }

      if (target.type == ChickenTargetType.boss && target.hitsRemaining > 1) {
        target.hitsRemaining--;
        _bursts.add(_TapBurst(
            x: bx, y: by, createdAt: _clock.elapsed, icon: '💪'));
        _message = '${target.hitsRemaining} more taps on the boss!';
        AudioService.instance.playSfx(Sfx.pop);
        return;
      }

      _targets.removeAt(index);
      _combo++;
      _bestCombo = math.max(_bestCombo, _combo);
      final points = ChickenTapRules.points(target.type, _combo);
      _score += points;
      // Floating "+N" so every catch feels rewarding.
      _bursts.add(_TapBurst(
          x: bx, y: by, createdAt: _clock.elapsed, icon: '+$points'));
      if (_playMode == MiniGamePlayMode.together) {
        final player = target.currentX(_clock.elapsed) < 0.5 ? 0 : 1;
        _playerScores[player] += points;
      }
      _struggleBoost = (_struggleBoost - 0.15).clamp(0.0, 1.0);
      if (target.type == ChickenTargetType.egg) {
        _eggsCollected++;
        _bonusSeconds += 3;
        _message = 'Egg power! +3 seconds!';
      } else if (target.type == ChickenTargetType.golden) {
        _message = 'Golden chicken! Five bonus points!';
      } else if (target.type == ChickenTargetType.boss) {
        _eggsCollected += 5;
        _message = 'Golden egg rain! Five eggs!';
        _celebration.fireworks();
      } else if (_combo > 0 && _combo % 5 == 0) {
        _message = 'Hot streak! Combo x$_combo!';
      } else {
        _message = 'Nice catch!';
      }
      AudioService.instance.playSfx(
        target.type == ChickenTargetType.golden ? Sfx.reward : Sfx.tap,
      );
      AudioService.instance.lightHaptic();
    });
  }

  void _endGame() {
    if (_gameOver) return;
    _gameOver = true;
    _ticker?.cancel();
    _clock.stop();
    _celebration.fireworks();
    final count = _countingLine(_eggsCollected);
    AudioService.instance.speak(
      _eggsCollected == 0
          ? 'Great catching! Let us find an egg next time!'
          : 'You got $count. $_eggsCollected eggs! Amazing!',
    );
    showMiniGameReward(context, _score);
    ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: '368-chickens',
      score: _score,
      achievements: [
        if (_bestCombo >= 10) 'chicken_combo_10',
      ],
    );
    if (mounted) {
      setState(() => _message = 'Great round! Can you beat your score?');
    }
  }

  String _countingLine(int total) {
    final spoken = math.min(total, 10);
    return [for (var i = 1; i <= spoken; i++) '$i'].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.jungle,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                MascotMessage(message: _message, icon: '🦁'),
                StoryGoalCard(
                  emoji: '🐔🥚',
                  goal: 'Help Mama Chicken collect the eggs!',
                  progress: _started
                      ? 1 - (_timeLeft / (_roundSeconds + _bonusSeconds))
                      : 0,
                  progressColor: const Color(0xFFFFD93D),
                ),
                const SizedBox(height: 5),
                if (_gameOver)
                  _gameOverScreen()
                else if (!_started)
                  _startScreen()
                else
                  Expanded(child: _gameArea()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          GameCircleButton(
            icon: Icons.close_rounded,
            tooltip: 'Close game',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '🐔 Chicken Tap',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          if (_started && !_gameOver) ...[
            Text(
              '⏱ $_timeLeft',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '⭐ $_score',
              style: const TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 6),
            GameCircleButton(
              icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              tooltip: _paused ? 'Resume' : 'Pause',
              onTap: _togglePause,
            ),
          ] else
            GameCircleButton(
              icon: Icons.help_outline_rounded,
              tooltip: 'How to play',
              onTap: () => showMiniGameHelp(
                context,
                title: 'How to play Chicken Tap',
                steps: const [
                  'Tap chickens before they run away.',
                  'Golden chickens give bonus points.',
                  'Eggs add three seconds. Avoid bombs.',
                  'The boss chicken needs three quick taps.',
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _startScreen() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OpenMojiView(
                emoji: '🐔',
                size: 94,
                fallback: Text('🐔', style: TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Catch the chickens!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              PlayModePicker(
                value: _playMode,
                onChanged: (value) => setState(() => _playMode = value),
              ),
              const SizedBox(height: 22),
              BouncyButton(
                onTap: _startGame,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD93D),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    '▶ START',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            if (_playMode == MiniGamePlayMode.together) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: const Color(0x18FFE66D),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              'P1 ⭐ ${_playerScores[0]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 3, color: Colors.white54),
                      Expanded(
                        child: ColoredBox(
                          color: const Color(0x1874B9FF),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              'P2 ⭐ ${_playerScores[1]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            for (final target in _targets)
              Positioned(
                left: target.currentX(_clock.elapsed) *
                    (constraints.maxWidth - target.size),
                top: target.currentY(_clock.elapsed) *
                    (constraints.maxHeight - target.size - 55),
                child: _targetWidget(target),
              ),
            for (final burst in _bursts)
              Positioned(
                left: burst.x * (constraints.maxWidth - 45),
                top: burst.y * (constraints.maxHeight - 80),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.6),
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) => Opacity(
                    opacity: (1.6 - scale).clamp(0, 1),
                    // Score pops rise as they fade for a satisfying "juice".
                    child: Transform.translate(
                      offset: Offset(0, -22 * (scale - 0.5)),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                  child: burst.isScore
                      ? Text(
                          burst.icon,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFE066),
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        )
                      : Text(burst.icon, style: const TextStyle(fontSize: 36)),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Column(
                children: [
                  if (_combo > 1)
                    Text(
                      '🔥 COMBO x$_combo',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  if (_noFail)
                    const Text(
                      '😊 Just for fun!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _maxMisses; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              i < _missed
                                  ? Icons.close_rounded
                                  : Icons.favorite_rounded,
                              color: i < _missed ? Colors.white54 : Colors.red,
                              size: 27,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (_paused)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _togglePause,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Resume'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _targetWidget(_ChickenTarget target) {
    final visual = switch (target.type) {
      ChickenTargetType.chicken => (emoji: '🐔', color: Colors.white),
      ChickenTargetType.golden => (emoji: '🐔', color: const Color(0xFFFFE66D)),
      ChickenTargetType.egg => (emoji: '🥚', color: const Color(0xFFDFF9FB)),
      ChickenTargetType.bomb => (emoji: '💣', color: const Color(0xFF2D3436)),
      ChickenTargetType.boss => (emoji: '🐔', color: const Color(0xFFFFD700)),
    };
    final life = target.life(_clock.elapsed);
    return Semantics(
      button: true,
      label: target.type.name,
      child: GestureDetector(
        onTap: () => _tapTarget(target.id),
        child: Opacity(
          opacity: life.clamp(0.35, 1),
          child: Transform.scale(
            scale: (0.76 + life * 0.24),
            child: Container(
              width: target.size,
              height: target.size,
              decoration: BoxDecoration(
                color: visual.color,
                shape: BoxShape.circle,
                border: target.type == ChickenTargetType.golden
                    ? Border.all(color: Colors.yellow, width: 4)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: visual.color.withValues(alpha: 0.65),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  OpenMojiView(
                    emoji: visual.emoji,
                    size: target.size * 0.67,
                    fallback: Text(
                      visual.emoji,
                      style: TextStyle(fontSize: target.size * 0.5),
                    ),
                  ),
                  if (target.type == ChickenTargetType.boss)
                    Positioned(
                      top: 0,
                      child: Text(
                        '👑 ${target.hitsRemaining}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameOverScreen() {
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐔👑', style: TextStyle(fontSize: 72)),
              const Text(
                'Round complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '🥚 $_eggsCollected eggs  •  ⭐ $_score  •  🔥 $_bestCombo',
                style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '🥚  🥚  🥚\n  🥚  🥚  🥚  🥚',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Play again'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Back to mini games',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChickenTarget {
  _ChickenTarget({
    required this.id,
    required this.type,
    required this.baseX,
    required this.y,
    required this.size,
    required this.phase,
    required this.amplitude,
    required this.vx,
    required this.hop,
    required this.spawnedAt,
    required this.expiresAt,
    required this.hitsRemaining,
  });

  final int id;
  final ChickenTargetType type;
  final double baseX;
  final double y;
  final double size;
  final double phase;
  final double amplitude;

  /// Horizontal patrol speed (screen fractions per second, signed). The chicken
  /// walks across and bounces off the edges — this is what makes it feel alive.
  final double vx;

  /// Hop height (screen fraction) — a little vertical bounce as it runs.
  final double hop;
  final Duration spawnedAt;
  final Duration expiresAt;
  int hitsRemaining;

  static const _lo = 0.02;
  static const _hi = 0.9;

  double currentX(Duration now) {
    final t = (now - spawnedAt).inMilliseconds / 1000;
    const span = _hi - _lo;
    // Triangle-wave reflection keeps the runner patrolling inside the field.
    const period = 2 * span;
    var p = (((baseX - _lo) + vx * t) % period + period) % period;
    if (p > span) p = period - p;
    return (_lo + p + math.sin(t * 4 + phase) * amplitude).clamp(_lo, _hi);
  }

  double currentY(Duration now) {
    final t = (now - spawnedAt).inMilliseconds / 1000;
    final bounce = math.sin(t * 7 + phase).abs() * hop;
    return (y - bounce).clamp(0.02, 0.8);
  }

  double life(Duration now) {
    final total = (expiresAt - spawnedAt).inMilliseconds;
    final remaining = (expiresAt - now).inMilliseconds;
    return (remaining / total).clamp(0.0, 1.0);
  }
}

class _TapBurst {
  const _TapBurst({
    required this.x,
    required this.y,
    required this.createdAt,
    required this.icon,
  });

  final double x;
  final double y;
  final Duration createdAt;
  final String icon;

  /// A floating score ("+5") rather than an emoji effect.
  bool get isScore => icon.startsWith('+');
}
