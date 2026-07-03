import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../logic/classic_2048_engine.dart';
import '../mini_games_controller.dart';

/// Classic 2048 — swipe tiles to merge and reach 2048!
class Classic2048Game extends ConsumerStatefulWidget {
  const Classic2048Game({super.key});

  @override
  ConsumerState<Classic2048Game> createState() => _Classic2048GameState();
}

class _Classic2048GameState extends ConsumerState<Classic2048Game> {
  late final Classic2048Engine _engine;

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
    1024: Color(0xFFC62828),
    2048: Color(0xFFB71C1C),
  };

  static const _textColors = {
    2: Color(0xFF1B5E20),
    4: Color(0xFF1B5E20),
    8: Colors.white,
    16: Colors.white,
    32: Colors.white,
    64: Colors.white,
    128: Colors.white,
    256: Colors.white,
    512: Colors.white,
    1024: Colors.white,
    2048: Colors.white,
  };

  @override
  void initState() {
    super.initState();
    _engine = Classic2048Engine();
  }

  void _reset() {
    setState(_engine.reset);
  }

  void _swipe(SwipeDirection direction) {
    if (_engine.gameOver || _engine.won) return;
    setState(() {
      _engine.move(direction);
    });
    if (_engine.won || _engine.gameOver) {
      ref.read(miniGamesControllerProvider.notifier).recordScore(
            '2048',
            _engine.score,
          );
    }
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
      body: AnimatedBackground(
        theme: WorldTheme.aurora,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              _gameBoard(),
              _controls(),
            ],
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
          BouncyButton(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.primary, size: 22),
              )),
          const SizedBox(width: 8),
          const Text('2048',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const Spacer(),
          Text('⭐ ${_engine.score}',
              style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          const SizedBox(width: 8),
          BouncyButton(
              onTap: _reset,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary, size: 22),
              )),
        ],
      ),
    );
  }

  Widget _gameBoard() {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: _handleSwipe,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_engine.won)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('🎉 You reached 2048!',
                      style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              if (_engine.gameOver)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('😵 No more moves!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    for (var r = 0; r < Classic2048Engine.size; r++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var c = 0; c < Classic2048Engine.size; c++)
                            _tile(r, c),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(int r, int c) {
    final val = _engine.grid[r][c];
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: val == 0
            ? Colors.white.withValues(alpha: 0.2)
            : (_tileColors[val] ?? Colors.white),
        borderRadius: BorderRadius.circular(8),
        boxShadow: val > 0
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
              ]
            : null,
      ),
      child: Center(
        child: Text(
          val == 0 ? '' : '$val',
          style: TextStyle(
            fontSize: val >= 100 ? 18 : 24,
            fontWeight: FontWeight.w900,
            color: _textColors[val] ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Swipe area
          GestureDetector(
            onPanEnd: _handleSwipe,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('👆 Swipe to move',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Arrow buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BouncyButton(
                  onTap: () => _swipe(SwipeDirection.left),
                  child: _arrowBtn(Icons.arrow_back_rounded)),
              const SizedBox(width: 8),
              Column(
                children: [
                  BouncyButton(
                      onTap: () => _swipe(SwipeDirection.up),
                      child: _arrowBtn(Icons.arrow_upward_rounded)),
                  const SizedBox(height: 4),
                  BouncyButton(
                      onTap: () => _swipe(SwipeDirection.down),
                      child: _arrowBtn(Icons.arrow_downward_rounded)),
                ],
              ),
              const SizedBox(width: 8),
              BouncyButton(
                  onTap: () => _swipe(SwipeDirection.right),
                  child: _arrowBtn(Icons.arrow_forward_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _arrowBtn(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }
}
