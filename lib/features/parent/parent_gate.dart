import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';

/// COPPA-style parent gate: a simple multi-digit arithmetic challenge that a
/// young child can't solve, blocking access to parent-only areas (dashboard,
/// purchases, account). Deliberately not a PIN a child could watch a parent type.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  // Fixed challenge (deterministic — no Random, which is unavailable in some
  // sandboxes and unnecessary here). Rotated by day-of-year at runtime.
  late final int _a = 3 + (DateTime.now().day % 7);
  late final int _b = 4 + (DateTime.now().day % 5);
  int get _answer => _a * _b;

  String _entry = '';
  bool _error = false;

  void _press(String d) {
    setState(() {
      _error = false;
      if (d == '⌫') {
        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
      } else if (_entry.length < 3) {
        _entry += d;
      }
      if (_entry.length >= _answer.toString().length) {
        if (int.tryParse(_entry) == _answer) {
          context.go(AppRoutes.parentDashboard);
        } else {
          _error = true;
          _entry = '';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.height < 620 || media.textScaler.scale(1) > 1.2;

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.night,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: BouncyButton(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 48),
                      Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        size: compact ? 44 : 56,
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Parents Only',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 26 : 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What is $_a × $_b ?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: compact ? 19 : 22,
                        ),
                      ),
                      SizedBox(height: compact ? 14 : 20),
                      Container(
                        height: compact ? 56 : 64,
                        width: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              const BorderRadius.all(AppSpacing.radiusMd),
                          border: _error
                              ? Border.all(color: AppColors.error, width: 3)
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _entry.isEmpty ? '?' : _entry,
                            style: TextStyle(
                              fontSize: compact ? 28 : 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (_error)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Try again',
                            style:
                                TextStyle(color: AppColors.error, fontSize: 16),
                          ),
                        ),
                      SizedBox(height: compact ? 18 : 36),
                      _keypad(compact: compact),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _keypad({required bool compact}) {
    const keys = [
      '1', '2', '3', //
      '4', '5', '6', //
      '7', '8', '9', //
      '', '0', '⌫', //
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 24) / 3;
        final cellHeight = compact ? 48.0 : 58.0;
        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: cellWidth / cellHeight,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final k in keys)
              k.isEmpty
                  ? const SizedBox.shrink()
                  : BouncyButton(
                      onTap: () => _press(k),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius:
                              const BorderRadius.all(AppSpacing.radiusMd),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            k,
                            style: TextStyle(
                              fontSize: compact ? 24 : 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
          ],
        );
      },
    );
  }
}
