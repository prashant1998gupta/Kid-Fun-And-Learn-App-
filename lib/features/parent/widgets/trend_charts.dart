import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_spacing.dart';

/// A compact, dependency-free bar chart for the parent dashboard's over-time
/// graphs. Bars are plain widgets (no CustomPainter) so they animate with
/// flutter_animate and scale cleanly with text size / theme.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.barHeight = 92,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    values[i] > 0 ? '${values[i]}' : '',
                    style: labelStyle?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: barHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _bar(_barExtent(values[i], maxVal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  double _barExtent(int value, int maxVal) {
    if (maxVal <= 0) return 4;
    return 4 + (barHeight - 4) * (value / maxVal);
  }

  Widget _bar(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
        borderRadius: const BorderRadius.vertical(top: AppSpacing.radiusSm),
      ),
    ).animate().scaleY(
          begin: 0,
          end: 1,
          alignment: Alignment.bottomCenter,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
