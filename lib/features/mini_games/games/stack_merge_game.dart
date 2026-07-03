import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../logic/stack_merge_engine.dart';
import '../mini_games_controller.dart';

/// Stack Merge — drop numbers to merge them bigger.
class StackMergeGame extends ConsumerStatefulWidget {
  const StackMergeGame({super.key});

  @override
  ConsumerState<StackMergeGame> createState() => _StackMergeGameState();
}

class _StackMergeGameState extends ConsumerState<StackMergeGame> {
  static const _cols = 5;
  late final StackMergeEngine _engine;
  int? _fallingValue;
  int _dropColumn = 2;
  int _nextValue = 2;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _engine = StackMergeEngine(columnCount: _cols);
    _restart();
  }

  void _startDrop() {
    if (_engine.gameOver || _fallingValue != null) return;
    setState(() {
      _fallingValue = _nextValue;
      _nextValue = _rnd.nextBool() ? 2 : 4;
    });
  }

  void _dropNow() {
    final value = _fallingValue;
    if (value == null || _engine.gameOver) return;
    setState(() {
      _engine.drop(_dropColumn, value);
      _fallingValue = null;
    });
    if (_engine.gameOver) {
      _endGame();
    }
  }

  void _moveLeft() {
    if (_fallingValue == null) return;
    setState(() {
      _dropColumn = (_dropColumn - 1).clamp(0, _cols - 1);
    });
  }

  void _moveRight() {
    if (_fallingValue == null) return;
    setState(() {
      _dropColumn = (_dropColumn + 1).clamp(0, _cols - 1);
    });
  }

  void _endGame() {
    ref.read(miniGamesControllerProvider.notifier).recordScore(
          'stack-merge',
          _engine.score,
        );
  }

  void _restart() {
    setState(() {
      _engine.reset();
      _fallingValue = null;
      _dropColumn = 2;
      _nextValue = _rnd.nextBool() ? 2 : 4;
      for (var i = 0; i < 3; i++) {
        _engine.drop(_rnd.nextInt(_cols), _rnd.nextBool() ? 2 : 4);
      }
    });
  }

  static const _valueColors = {
    2: Color(0xFFE74C3C),
    4: Color(0xFFF39C12),
    8: Color(0xFFF1C40F),
    16: Color(0xFF2ECC71),
    32: Color(0xFF3498DB),
    64: Color(0xFF9B59B6),
    128: Color(0xFFE91E63),
    256: Color(0xFF00CEC9),
    512: Color(0xFFFDCB6E),
    1024: Color(0xFF6C5CE7),
    2048: Color(0xFFE17055),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _gameArea()),
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
          const Expanded(
            child: Text(
              '🔢 Stack Merge',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
          Text('⭐ ${_engine.score}',
              style: const TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(width: 12),
          if (_engine.gameOver)
            BouncyButton(
                onTap: _restart,
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

  Widget _gameArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_fallingValue == null && !_engine.gameOver)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BouncyButton(
              onTap: _startDrop,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24)),
                child: Text('Drop $_nextValue',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ),
            ),
          ),
        if (_engine.gameOver)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                const Text('Game Over!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                Text('⭐ ${_engine.score}',
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        Container(
          width: 250,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              for (var col = 0; col < _engine.columns.length; col++)
                for (var row = 0; row < _engine.columns[col].length; row++)
                  Positioned(
                    left: col * 50.0 + 4,
                    bottom: row * 44.0 + 4,
                    child: _tileWidget(_engine.columns[col][row]),
                  ),
              if (_fallingValue != null)
                Positioned(
                  left: _dropColumn * 50.0 + 4,
                  top: 8,
                  child: _tileWidget(_fallingValue!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tileWidget(int value) {
    return Container(
      width: 42,
      height: 40,
      decoration: BoxDecoration(
        color: _valueColors[value] ?? Colors.purple,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)
        ],
      ),
      child: Center(
        child: Text('$value',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16)),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BouncyButton(
            onTap: _moveLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 24),
          BouncyButton(
            onTap: _dropNow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.arrow_downward_rounded,
                  color: AppColors.primary, size: 28),
            ),
          ),
          const SizedBox(width: 24),
          BouncyButton(
            onTap: _moveRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.primary, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
