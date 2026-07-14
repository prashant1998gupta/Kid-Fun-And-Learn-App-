import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constants/feedback_timing.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/openmoji_view.dart';
import '../../settings/settings_controller.dart';
import '../logic/classic_2048_engine.dart';
import '../mini_games_controller.dart';
import '../widgets/game_tutorial.dart';
import '../widgets/mini_game_widgets.dart';

class Classic2048Game extends ConsumerStatefulWidget {
  const Classic2048Game({super.key});

  @override
  ConsumerState<Classic2048Game> createState() => _Classic2048GameState();
}

class _Classic2048GameState extends ConsumerState<Classic2048Game> {
  late Classic2048Engine _engine;
  // Default to Easy so young children win quickly and often.
  final MiniGameDifficulty _difficulty = MiniGameDifficulty.easy;
  MiniGamePlayMode _playMode = MiniGamePlayMode.solo;
  int _currentPlayer = 1;
  bool _resultRecorded = false;
  bool _holdingSuccess = false;
  int _boardSession = 0;
  bool _tiltEnabled = false;
  StreamSubscription<AccelerometerEvent>? _tiltSubscription;
  DateTime _lastTilt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _animalMode = true; // animals read friendlier than raw numbers
  bool _lastMoveBlocked = false;
  int _boardPulse = 0;
  int _friendPulse = 0;
  int _newFriendValue = 0;
  String _message = 'Join two the same to make it bigger!';
  final _celebration = CelebrationController();

  static const _tileColors = {
    2: Color(0xFFE8F5E9),
    4: Color(0xFFC8E6C9),
    8: Color(0xFFFFF3E0),
    16: Color(0xFFFFE0B2),
    32: Color(0xFFFFCC80),
    64: Color(0xFFFF8A65),
    128: Color(0xFFFF7043),
    256: Color(0xFFF4511E),
    512: Color(0xFFD32F2F),
    1024: Color(0xFF8E44AD),
    2048: Color(0xFF6C5CE7),
  };

  static const _animals = {
    2: '🐣',
    4: '🐰',
    8: '🐶',
    16: '🐱',
    32: '🦊',
    64: '🐼',
    128: '🦁',
    256: '🦄',
    512: '🐉',
    1024: '🐋',
    2048: '👑',
  };

  static const _animalNames = {
    2: 'Chick',
    4: 'Bunny',
    8: 'Puppy',
    16: 'Kitty',
    32: 'Fox',
    64: 'Panda',
    128: 'Lion',
    256: 'Unicorn',
    512: 'Dragon',
    1024: 'Whale',
    2048: 'King',
  };

  static const _animalSounds = {
    2: 'peep peep',
    4: 'boing boing',
    8: 'woof woof',
    16: 'meow',
    32: 'yip yip',
    64: 'munch munch',
    128: 'roar',
    256: 'sparkle sparkle',
    512: 'rawr',
    1024: 'whoosh',
    2048: 'ta da',
  };

  @override
  void initState() {
    super.initState();
    _engine = Classic2048Engine(size: _boardSize, targetTile: _targetTile);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showFirstPlayTutorial(
          context,
          ref,
          gameId: '2048',
          instruction: 'Swipe to slide the animals. Join two of the same to '
              'grow a bigger one!',
        );
      }
    });
  }

  @override
  void dispose() {
    _tiltSubscription?.cancel();
    super.dispose();
  }

  // Easy uses a roomy 4x4 with a low goal; harder modes raise the goal, not the
  // survival pressure, so it never feels punishing for a child.
  int get _boardSize => switch (_difficulty) {
        MiniGameDifficulty.easy => 4,
        MiniGameDifficulty.normal => 4,
        MiniGameDifficulty.challenge => 5,
      };

  int get _targetTile => switch (_difficulty) {
        MiniGameDifficulty.easy => 64,
        MiniGameDifficulty.normal => 256,
        MiniGameDifficulty.challenge => 1024,
      };

  void _reset() {
    setState(() {
      _boardSession++;
      _engine = Classic2048Engine(size: _boardSize, targetTile: _targetTile);
      _message = 'New board — plan your next move!';
      _currentPlayer = 1;
      _resultRecorded = false;
      _lastMoveBlocked = false;
      _boardPulse = 0;
      _friendPulse = 0;
      _newFriendValue = 0;
      _holdingSuccess = false;
    });
  }

  void _undo() {
    if (_holdingSuccess) return;
    if (_engine.undo()) {
      AudioService.instance.playSfx(Sfx.whoosh);
      setState(() => _message = 'Move undone. Try another direction!');
    }
  }

  Future<void> _swipe(SwipeDirection direction) async {
    if (_holdingSuccess ||
        _engine.gameOver ||
        (_engine.won && !_engine.keepPlaying)) {
      return;
    }
    final session = _boardSession;
    final oldHighest = _engine.highestTile;
    final oldScore = _engine.score;
    final wasWon = _engine.won;
    final moved = _engine.move(direction);
    if (!moved) {
      setState(() {
        _message = 'That side is blocked.';
        _lastMoveBlocked = true;
        _boardPulse++;
      });
      AudioService.instance.playSfx(Sfx.pop);
      return;
    }

    final merged = _engine.score > oldScore;
    final madeNewTile = _engine.highestTile > oldHighest;
    final newAnimal = _animalNames[_engine.highestTile];
    setState(() {
      _lastMoveBlocked = false;
      _boardPulse++;
      _holdingSuccess = merged;
      _message = madeNewTile
          ? (_animalMode && newAnimal != null
              ? 'You made a $newAnimal! ${_animals[_engine.highestTile]}'
              : 'Great merge! You made ${_engine.highestTile}.')
          : merged
              ? 'Great match! Watch them grow! ✨'
              : 'Keep matching to grow!';
      if (madeNewTile) {
        _newFriendValue = _engine.highestTile;
        _friendPulse++;
      }
    });
    AudioService.instance.playSfx(merged ? Sfx.correct : Sfx.tap);
    if (madeNewTile) {
      AudioService.instance.lightHaptic();
      // Celebrate reaching a brand-new animal — the real goal for a child.
      if (_animalMode && newAnimal != null) {
        AudioService.instance.speak(
          'You made a $newAnimal! ${_animalSounds[_engine.highestTile]}!',
        );
        _celebration.celebrate(sound: false);
      } else {
        AudioService.instance.speak(PraiseLines.nextSuccess());
        _celebration.celebrate(sound: false);
      }
    } else if (merged) {
      AudioService.instance.lightHaptic();
      _celebration.celebrate(sound: false);
      AudioService.instance.speak(PraiseLines.nextSuccess());
    }

    final newlyWon = !wasWon && _engine.won;
    if (newlyWon) {
      _celebration.fireworks();
      AudioService.instance.speak('Amazing! You reached $_targetTile!');
    }
    if (merged) {
      await Future<void>.delayed(FeedbackTiming.successBeat);
      if (!mounted || session != _boardSession) return;
      setState(() => _holdingSuccess = false);
    }
    if (_playMode == MiniGamePlayMode.together) {
      setState(() {
        _currentPlayer = _currentPlayer == 1 ? 2 : 1;
        _message = 'Great move! Player $_currentPlayer, your turn!';
      });
    }
    if (newlyWon) _recordResult();
    if (_engine.gameOver) _friendlyRescue();
  }

  void _friendlyRescue() {
    if (!_resultRecorded) _recordResult();
    final cleared = _engine.rescue(count: 3);
    setState(() {
      _message = 'Puff! The dragon made $cleared spaces. Keep growing!';
    });
    _celebration.celebrate(sound: false);
    AudioService.instance.playSfx(Sfx.magic);
    AudioService.instance.speak("Let's keep playing! I made some room.");
  }

  void _recordResult() {
    if (_resultRecorded) return;
    _resultRecorded = true;
    showMiniGameReward(context, _engine.score);
    ref.read(miniGamesControllerProvider.notifier).recordResult(
      gameId: '2048',
      score: _engine.score,
      achievements: [
        if (_engine.highestTile >= 256) '2048_256',
      ],
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < 80) return;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      _swipe(velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      _swipe(velocity.dy > 0 ? SwipeDirection.down : SwipeDirection.up);
    }
  }

  void _toggleTilt() {
    if (_tiltEnabled) {
      _tiltSubscription?.cancel();
      setState(() => _tiltEnabled = false);
      return;
    }
    setState(() {
      _tiltEnabled = true;
      _message = 'Tilt the device to roll the animal family!';
    });
    AudioService.instance.speak('Tilt the device left, right, up, or down!');
    _tiltSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 180),
    ).listen(
      (event) {
        if (!mounted || !_tiltEnabled) return;
        final now = DateTime.now();
        if (now.difference(_lastTilt) < const Duration(milliseconds: 650)) {
          return;
        }
        SwipeDirection? direction;
        if (event.x.abs() > 4.2 && event.x.abs() > event.y.abs()) {
          direction = event.x > 0 ? SwipeDirection.left : SwipeDirection.right;
        } else if (event.y.abs() > 4.2) {
          direction = event.y > 0 ? SwipeDirection.down : SwipeDirection.up;
        }
        if (direction != null) {
          _lastTilt = now;
          _swipe(direction);
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            _tiltEnabled = false;
            _message = 'Tilt is not available here—swiping still works!';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.aurora,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 620 || constraints.maxWidth < 340;
                return Column(
                  children: [
                    _topBar(compact: compact),
                    if (compact)
                      _compactGoal()
                    else ...[
                      MascotMessage(message: _message, icon: '🦉'),
                      StoryGoalCard(
                        emoji: '🐣➡️🐉',
                        goal: 'Grow the baby dragon family!',
                        progress:
                            (_engine.highestTile / _targetTile).clamp(0, 1),
                      ),
                    ],
                    SizedBox(height: compact ? 3 : 6),
                    Expanded(child: _gameBoard(compact: compact)),
                    _controls(compact: compact),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar({required bool compact}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 6 : AppSpacing.sm),
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
              '🐉 Animal Family',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            '⭐ ${_engine.score}',
            style: const TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
          GameCircleButton(
            icon: Icons.undo_rounded,
            tooltip: 'Undo',
            onTap: _undo,
          ),
          const SizedBox(width: 5),
          GameCircleButton(
            icon: _tiltEnabled
                ? Icons.screen_rotation_alt_rounded
                : Icons.screen_rotation_rounded,
            tooltip: _tiltEnabled ? 'Turn tilt off' : 'Play by tilting',
            onTap: _toggleTilt,
          ),
          const SizedBox(width: 5),
          GameCircleButton(
            icon: Icons.help_outline_rounded,
            tooltip: 'How to play',
            onTap: () => showMiniGameHelp(
              context,
              title: 'How to play 2048',
              steps: [
                'Swipe or tap the arrows to slide every tile.',
                'Two of the same join into a bigger one!',
                'Tap Undo if a move gets you stuck.',
                'Reach the $_targetTile tile to win — then keep going!',
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactGoal() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🐣', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Grow the baby dragon family!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.lightText,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: LinearProgressIndicator(
              value: (_engine.highestTile / _targetTile).clamp(0, 1),
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.star,
              backgroundColor: Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameBoard({required bool compact}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(0.0, constraints.maxWidth - 24);
        final boardWidth = math.min(390.0, availableWidth);
        final tileSize = (boardWidth - 12 - (_engine.size * 6)) / _engine.size;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: _handleSwipe,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlayModePicker(
                  value: _playMode,
                  onChanged: (value) => setState(() {
                    _playMode = value;
                    _currentPlayer = 1;
                  }),
                ),
                if (_playMode == MiniGamePlayMode.together) ...[
                  const SizedBox(height: 6),
                  PlayerTurnBadge(player: _currentPlayer),
                ],
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('123 Numbers')),
                    ButtonSegment(value: true, label: Text('🐾 Animals')),
                  ],
                  selected: {_animalMode},
                  onSelectionChanged: (value) =>
                      setState(() => _animalMode = value.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? AppColors.primary
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_engine.won && !_engine.keepPlaying)
                  _statusCard(
                    '🎉 You reached $_targetTile!',
                    'Keep playing',
                    () => setState(_engine.continueAfterWin),
                  ),
                _animatedBoard(boardWidth, tileSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _animatedBoard(double boardWidth, double tileSize) {
    final newAnimal = _animals[_newFriendValue];
    return TweenAnimationBuilder<double>(
      key: ValueKey('board-$_boardPulse-$_lastMoveBlocked'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        if (_lastMoveBlocked) {
          final shake = math.sin(t * math.pi * 6) * (1 - t) * 8;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        }
        final scale = 1 + math.sin(t * math.pi) * 0.025;
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: boardWidth,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var r = 0; r < _engine.size; r++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var c = 0; c < _engine.size; c++)
                        _tile(r, c, tileSize),
                    ],
                  ),
              ],
            ),
          ),
          if (_friendPulse > 0 && newAnimal != null)
            Positioned(
              key: ValueKey('friend-$_friendPulse'),
              top: 10,
              right: 10,
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 780),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Opacity(
                    opacity: (1 - t).clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(0, -28 * t),
                      child: Transform.scale(
                        scale: 0.6 + t * 0.8,
                        child: child,
                      ),
                    ),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      '$newAnimal New friend!',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$title  •  $action',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(int row, int col, double size) {
    final value = _engine.grid[row][col];
    final animal = _animals[value];
    final colorBlind = ref.watch(settingsControllerProvider).colorBlindMode;
    const shapes = ['●', '■', '▲', '◆', '⬟', '✚', '✦'];
    final shape = value > 0
        ? shapes[((math.log(value) / math.ln2).round() - 1) % shapes.length]
        : '';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value == 0
            ? Colors.white.withValues(alpha: 0.18)
            : (_tileColors[value] ?? const Color(0xFF6C5CE7)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: value > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: value == 0
          ? null
          : _animalMode && animal != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('$row-$col-$value'),
                        tween: Tween(begin: 0.72, end: 1),
                        duration: ref.watch(reducedMotionProvider)
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: OpenMojiView(
                          emoji: animal,
                          size: size * 0.62,
                          fallback: Text(
                            animal,
                            style: TextStyle(fontSize: size * 0.46),
                          ),
                        ),
                      ),
                    ),
                    // A high-contrast corner badge keeps the number crisp and
                    // readable no matter what animal art sits behind it.
                    Positioned(
                      top: 3,
                      left: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: size * 0.2,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    colorBlind ? '$shape\n$value' : '$value',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: value >= 1000 ? size * 0.28 : size * 0.38,
                      fontWeight: FontWeight.w900,
                      color:
                          value <= 4 ? const Color(0xFF1B5E20) : Colors.white,
                    ),
                  ),
                ),
    );
  }

  Widget _controls({required bool compact}) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 14, top: compact ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _arrowButton(Icons.arrow_back_rounded, SwipeDirection.left,
              compact: compact),
          SizedBox(width: compact ? 6 : 8),
          Column(
            children: [
              _arrowButton(Icons.arrow_upward_rounded, SwipeDirection.up,
                  compact: compact),
              SizedBox(height: compact ? 3 : 4),
              _arrowButton(Icons.arrow_downward_rounded, SwipeDirection.down,
                  compact: compact),
            ],
          ),
          SizedBox(width: compact ? 6 : 8),
          _arrowButton(Icons.arrow_forward_rounded, SwipeDirection.right,
              compact: compact),
          SizedBox(width: compact ? 7 : 10),
          GameCircleButton(
            icon: Icons.refresh_rounded,
            tooltip: 'New board',
            onTap: _reset,
          ),
        ],
      ),
    );
  }

  Widget _arrowButton(
    IconData icon,
    SwipeDirection direction, {
    required bool compact,
  }) {
    return BouncyButton(
      onTap: () => _swipe(direction),
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary, size: compact ? 21 : 24),
      ),
    );
  }
}
