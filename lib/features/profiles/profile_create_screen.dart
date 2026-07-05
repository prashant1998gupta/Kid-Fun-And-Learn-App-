import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import 'domain/child_profile.dart';
import 'domain/grade_level.dart';
import 'profiles_controller.dart';
import 'widgets/avatar_view.dart';

/// Create a child: name → grade → avatar customization. Live preview updates as
/// the parent (or child) plays with the options.
class ProfileCreateScreen extends ConsumerStatefulWidget {
  const ProfileCreateScreen({super.key});

  @override
  ConsumerState<ProfileCreateScreen> createState() =>
      _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends ConsumerState<ProfileCreateScreen> {
  final _nameController = TextEditingController();
  GradeLevel _grade = GradeLevel.lkg;
  AvatarConfig _avatar = const AvatarConfig();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _randomizeAvatarField(String field) {
    setState(() {
      _avatar = switch (field) {
        'skin' => _avatar.copyWith(skin: (_avatar.skin + 1) % 5),
        'hair' => _avatar.copyWith(hairColor: (_avatar.hairColor + 1) % 5),
        'face' => _avatar.copyWith(outfit: (_avatar.outfit + 1) % 6),
        'acc' => _avatar.copyWith(accessory: (_avatar.accessory + 1) % 6),
        'bg' => _avatar.copyWith(background: (_avatar.background + 1) % 5),
        _ => _avatar,
      };
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a name 😊')),
      );
      return;
    }
    await ref.read(profilesControllerProvider.notifier).addChild(
          name: name,
          grade: _grade,
          avatar: _avatar,
        );
    AudioService.instance.speak('Yay! Welcome, $name!');
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    BouncyButton(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Create Your Character',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
                const SizedBox(height: 20),
                AvatarView(config: _avatar, size: 150),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _customChip(Icons.face_rounded, 'Skin', 'skin'),
                    _customChip(Icons.brush_rounded, 'Hair', 'hair'),
                    _customChip(Icons.emoji_emotions_rounded, 'Face', 'face'),
                    _customChip(Icons.auto_awesome_rounded, 'Extras', 'acc'),
                    _customChip(Icons.wallpaper_rounded, 'Color', 'bg'),
                  ],
                ),
                const SizedBox(height: 24),
                _card(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      color: AppColors.lightText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      hintText: "What's your name?",
                      hintStyle: TextStyle(
                        color: AppColors.lightTextSoft,
                        fontWeight: FontWeight.w700,
                      ),
                      border: InputBorder.none,
                      icon: Icon(Icons.badge_rounded, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your class',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppColors.lightText),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final g in GradeLevel.values)
                            ChoiceChip(
                              label: Text(g.label),
                              selected: _grade == g,
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _grade == g
                                    ? Colors.white
                                    : AppColors.lightText,
                              ),
                              selectedColor: AppColors.primary,
                              backgroundColor: const Color(0xFFF1EFFF),
                              checkmarkColor: Colors.white,
                              side: BorderSide(
                                color: _grade == g
                                    ? AppColors.primary
                                    : const Color(0xFFD8D2F0),
                              ),
                              shape: const StadiumBorder(),
                              onSelected: (_) => setState(() => _grade = g),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                BouncyButton(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.success, AppColors.mint],
                      ),
                      borderRadius:
                          const BorderRadius.all(AppSpacing.radiusPill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Let's Play!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customChip(IconData icon, String label, String field) {
    return BouncyButton(
      onTap: () => _randomizeAvatarField(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: child,
    );
  }
}
