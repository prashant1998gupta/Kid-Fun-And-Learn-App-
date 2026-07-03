import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Credits & licenses. Also satisfies the OpenMoji CC BY-SA 4.0 attribution
/// requirement (illustrations) and credits the open fonts.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.bubblegum],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: AppColors.star, size: 52),
                ),
                const SizedBox(height: 12),
                Text('KidVerse', style: text.headlineMedium),
                Text('A joyful learning universe for kids',
                    style: text.bodyMedium),
                const SizedBox(height: 4),
                Text('Version 0.1.0', style: text.labelMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _CreditCard(
            title: 'Illustrations — OpenMoji',
            body: 'Colorful object art is from OpenMoji (openmoji.org), used '
                'under the Creative Commons Attribution-ShareAlike 4.0 license '
                '(CC BY-SA 4.0). Modifications (resizing/rendering) are shared '
                'under the same license.',
            icon: Icons.palette_rounded,
          ),
          const _CreditCard(
            title: 'Fonts',
            body: 'Baloo 2 and Nunito via Google Fonts, under the SIL Open '
                'Font License 1.1.',
            icon: Icons.font_download_rounded,
          ),
          const _CreditCard(
            title: 'Privacy',
            body: 'KidVerse is offline-first and COPPA-minded: children have no '
                'accounts, and no child personal information is collected. '
                'Cloud sync and leaderboards are optional and parent-controlled.',
            icon: Icons.shield_rounded,
          ),
        ],
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
