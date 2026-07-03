import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/bouncy_button.dart';
import '../../../core/widgets/openmoji_view.dart';
import '../mini_games_controller.dart';

/// Chicken Tap — tap chickens before they run away!
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
  bool _gameOver = false;
  bool _started = false;
  final List<_Chicken> _chickens = [];
  final math.Random _random = math.Random();
  int _nextId = 0;
  Timer? _ticker;
  final Stopwatch _clock = Stopwatch();
  Duration _nextSpawn = Duration.zero;
  int _timeLeft = 30;

  static const _maxChickens = 5;
  static const _maxMisses = 3;

  void _startGame() {
    setState(() {
      _started = true;
      _score = 0;
      _missed = 0;
      _combo = 0;
      _bestCombo = 0;
      _gameOver = false;
      _timeLeft = 30;
      _chickens.clear();
    });
    _clock
      ..reset()
      ..start();
    _nextSpawn = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (_gameOver || !mounted) return;
    final elapsed = _clock.elapsed;
    final progress = (elapsed.inMilliseconds / 30000).clamp(0.0, 1.0);
    var shouldEnd = false;
    setState(() {
      _timeLeft = (30 - elapsed.inMilliseconds / 1000).ceil().clamp(0, 30);
      if (elapsed >= _nextSpawn) {
        final lifetimeMs = (1800 - 800 * progress).round();
        _chickens.add(_Chicken(
          id: _nextId++,
          x: _random.nextDouble() * 0.8 + 0.1,
          y: _random.nextDouble() * 0.6 + 0.05,
          size: 44 + _random.nextDouble() * 18,
          spawnedAt: elapsed,
          expiresAt: elapsed + Duration(milliseconds: lifetimeMs),
        ));
        final spawnMs = (1200 - 650 * progress).round();
        _nextSpawn = elapsed + Duration(milliseconds: spawnMs);
      }
      for (var i = _chickens.length - 1; i >= 0; i--) {
        final chicken = _chickens[i];
        if (elapsed >= chicken.expiresAt) {
          _chickens.removeAt(i);
          _missed++;
          _combo = 0;
          AudioService.instance.playSfx(Sfx.pop);
        }
      }
      while (_chickens.length > _maxChickens) {
        _chickens.removeAt(0);
        _missed++;
        _combo = 0;
      }
      shouldEnd =
          _missed >= _maxMisses || elapsed >= const Duration(seconds: 30);
    });
    if (shouldEnd) _endGame();
  }

  void _tapChicken(int id) {
    if (_gameOver) return;
    setState(() {
      final index = _chickens.indexWhere((chicken) => chicken.id == id);
      if (index < 0) return;
      _chickens.removeAt(index);
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
      final bonus = (_combo > 1) ? _combo : 1;
      _score += bonus;
      AudioService.instance.playSfx(Sfx.tap);
    });
  }

  void _endGame() {
    if (_gameOver) return;
    _gameOver = true;
    _ticker?.cancel();
    _clock.stop();
    AudioService.instance.playSfx(Sfx.celebration);
    ref.read(miniGamesControllerProvider.notifier).recordScore(
          '368-chickens',
          _score,
        );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.jungle,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
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
            ),
          ),
          const SizedBox(width: 8),
          const Text('🐔 Chicken Tap',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const Spacer(),
          if (_started && !_gameOver) ...[
            Text('⏱️ $_timeLeft',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(width: 12),
            Text('⭐ $_score',
                style: const TextStyle(
                    color: Colors.yellow,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            if (_combo > 1) ...[
              const SizedBox(width: 8),
              Text('🔥$_combo',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _startScreen() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐔', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text('Tap the chickens!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Miss 3 and it\'s game over',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 24),
            BouncyButton(
              onTap: _startGame,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Text('▶️ START',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameArea() {
    return Stack(
      children: [
        for (final c in _chickens)
          Positioned(
            left: c.x * (MediaQuery.of(context).size.width - 80),
            top: c.y * (MediaQuery.of(context).size.height * 0.6),
            child: GestureDetector(
              onTap: () => _tapChicken(c.id),
              child: Opacity(
                opacity: c.life(_clock.elapsed).clamp(0.25, 1.0),
                child: Transform.scale(
                  scale: c.life(_clock.elapsed).clamp(0.65, 1.0),
                  child: Container(
                    width: c.size,
                    height: c.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(c.size),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.5),
                            blurRadius: 12)
                      ],
                    ),
                    child: const Center(
                      child: OpenMojiView(
                        emoji: '🐔',
                        size: 38,
                        fallback: Text('🐔', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Miss counter
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _maxMisses; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _missed ? Icons.close_rounded : Icons.favorite_rounded,
                    color: i < _missed ? Colors.grey : Colors.red,
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gameOverScreen() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Game Over!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('⭐ Score: $_score',
                style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('🔥 Best Combo: $_bestCombo',
                style: const TextStyle(color: Colors.orange, fontSize: 18)),
            const SizedBox(height: 24),
            BouncyButton(
              onTap: _startGame,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12)
                  ],
                ),
                child: const Text('🔄 Play Again',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            BouncyButton(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('🏠 Back',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chicken {
  _Chicken({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.spawnedAt,
    required this.expiresAt,
  });
  final int id;
  final double x;
  final double y;
  final double size;
  final Duration spawnedAt;
  final Duration expiresAt;

  double life(Duration now) {
    final total = (expiresAt - spawnedAt).inMilliseconds;
    final remaining = (expiresAt - now).inMilliseconds;
    return (remaining / total).clamp(0.0, 1.0);
  }
}
