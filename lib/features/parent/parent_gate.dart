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
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.night,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                const Spacer(),
                const Icon(Icons.lock_rounded, color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Parents Only',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What is $_a × $_b ?',
                  style: const TextStyle(color: Colors.white70, fontSize: 22),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 64,
                  width: 160,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
                    border: _error
                        ? Border.all(color: AppColors.error, width: 3)
                        : null,
                  ),
                  child: Text(
                    _entry.isEmpty ? '?' : _entry,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_error)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Try again',
                      style: TextStyle(color: AppColors.error, fontSize: 16),
                    ),
                  ),
                const Spacer(),
                _keypad(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypad() {
    const keys = [
      '1', '2', '3', //
      '4', '5', '6', //
      '7', '8', '9', //
      '', '0', '⌫', //
    ];
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
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
                      borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
      ],
    );
  }
}
