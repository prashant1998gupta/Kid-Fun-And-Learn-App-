import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/celebration_overlay.dart';
import '../../../core/widgets/openmoji_view.dart';
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
  MiniGameDifficulty _difficulty = MiniGameDifficulty.easy;
  bool _animalMode = true; // animals read friendlier than raw numbers
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
      _engine = Classic2048Engine(size: _boardSize, targetTile: _targetTile);
      _message = 'New board — plan your next move!';
    });
  }

  void _changeDifficulty(MiniGameDifficulty value) {
    _difficulty = value;
    _reset();
  }

  void _undo() {
    if (_engine.undo()) {
      AudioService.instance.playSfx(Sfx.whoosh);
      setState(() => _message = 'Move undone. Try another direction!');
    }
  }

  void _swipe(SwipeDirection direction) {
    if (_engine.gameOver || (_engine.won && !_engine.keepPlaying)) return;
    final oldHighest = _engine.highestTile;
    final wasWon = _engine.won;
    final moved = _engine.move(direction);
    if (!moved) {
      setState(() => _message = 'That side is blocked.');
      return;
    }

    final madeNewTile = _engine.highestTile > oldHighest;
    final newAnimal = _animalNames[_engine.highestTile];
    setState(() {
      _message = madeNewTile
          ? (_animalMode && newAnimal != null
              ? 'You made a $newAnimal! ${_animals[_engine.highestTile]}'
              : 'Great merge! You made ${_engine.highestTile}.')
          : 'Keep matching to grow!';
    });
    AudioService.instance.playSfx(madeNewTile ? Sfx.correct : Sfx.tap);
    if (madeNewTile) {
      AudioService.instance.lightHaptic();
      // Celebrate reaching a brand-new animal — the real goal for a child.
      if (_animalMode && newAnimal != null) {
        AudioService.instance.speak('You made a $newAnimal!');
        _celebration.celebrate(sound: false);
      }
    }

    final newlyWon = !wasWon && _engine.won;
    if (newlyWon) {
      _celebration.fireworks();
      AudioService.instance.speak('Amazing! You reached $_targetTile!');
    }
    if (newlyWon || _engine.gameOver) _recordResult();
  }

  void _recordResult() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CelebrationOverlay(
        controller: _celebration,
        child: AnimatedBackground(
          theme: WorldTheme.aurora,
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                MascotMessage(message: _message, icon: '🦉'),
                const SizedBox(height: 6),
                Expanded(child: _gameBoard()),
                _controls(),
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
          const Text(
            '2048',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const Spacer(),
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

  Widget _gameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = (constraints.maxWidth - 24).clamp(220.0, 390.0);
        final tileSize = (boardWidth - 12 - (_engine.size * 6)) / _engine.size;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: _handleSwipe,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DifficultyPicker(
                  value: _difficulty,
                  onChanged: _changeDifficulty,
                ),
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
                if (_engine.gameOver)
                  _statusCard('No more moves', 'New board', _reset),
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
              ],
            ),
          ),
        );
      },
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
          : Center(
              child: _animalMode && animal != null
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        OpenMojiView(
                          emoji: animal,
                          size: size * 0.58,
                          fallback: Text(
                            animal,
                            style: TextStyle(fontSize: size * 0.42),
                          ),
                        ),
                        Text(
                          '$value',
                          style: TextStyle(
                            fontSize: size * 0.18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$value',
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

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _arrowButton(Icons.arrow_back_rounded, SwipeDirection.left),
          const SizedBox(width: 8),
          Column(
            children: [
              _arrowButton(Icons.arrow_upward_rounded, SwipeDirection.up),
              const SizedBox(height: 4),
              _arrowButton(Icons.arrow_downward_rounded, SwipeDirection.down),
            ],
          ),
          const SizedBox(width: 8),
          _arrowButton(Icons.arrow_forward_rounded, SwipeDirection.right),
          const SizedBox(width: 10),
          GameCircleButton(
            icon: Icons.refresh_rounded,
            tooltip: 'New board',
            onTap: _reset,
          ),
        ],
      ),
    );
  }

  Widget _arrowButton(IconData icon, SwipeDirection direction) {
    return BouncyButton(
      onTap: () => _swipe(direction),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}
