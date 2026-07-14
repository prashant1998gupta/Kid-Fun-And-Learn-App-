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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final pagePadding = compact ? AppSpacing.md : AppSpacing.lg;
              final avatarSize = compact ? 118.0 : 150.0;
              return SingleChildScrollView(
                padding: EdgeInsets.all(pagePadding),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: (compact
                                    ? Theme.of(context).textTheme.headlineSmall
                                    : Theme.of(context).textTheme.headlineLarge)
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 50),
                      ],
                    ),
                    SizedBox(height: compact ? 14 : 20),
                    AvatarView(config: _avatar, size: avatarSize),
                    SizedBox(height: compact ? 14 : 20),
                    Wrap(
                      spacing: compact ? 8 : 12,
                      runSpacing: compact ? 8 : 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _customChip(Icons.face_rounded, 'Skin', 'skin',
                            compact: compact),
                        _customChip(Icons.brush_rounded, 'Hair', 'hair',
                            compact: compact),
                        _customChip(
                            Icons.emoji_emotions_rounded, 'Face', 'face',
                            compact: compact),
                        _customChip(Icons.auto_awesome_rounded, 'Extras', 'acc',
                            compact: compact),
                        _customChip(Icons.wallpaper_rounded, 'Color', 'bg',
                            compact: compact),
                      ],
                    ),
                    SizedBox(height: compact ? 18 : 24),
                    _card(
                      compact: compact,
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(
                          color: AppColors.lightText,
                          fontSize: compact ? 19 : 22,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          hintText: "What's your name?",
                          hintStyle: TextStyle(
                            color: AppColors.lightTextSoft,
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.badge_rounded,
                              color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      compact: compact,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose your class',
                            style: (compact
                                    ? Theme.of(context).textTheme.titleMedium
                                    : Theme.of(context).textTheme.titleLarge)
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
                        padding:
                            EdgeInsets.symmetric(vertical: compact ? 15 : 18),
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
                        child: Text(
                          "Let's Play!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 20 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _customChip(
    IconData icon,
    String label,
    String field, {
    required bool compact,
  }) {
    return BouncyButton(
      onTap: () => _randomizeAvatarField(field),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 13 : 18,
          vertical: compact ? 10 : 12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: compact ? 20 : 24),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.lightText,
                fontSize: compact ? 13 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, required bool compact}) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.all(AppSpacing.md)
          : AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: child,
    );
  }
}
