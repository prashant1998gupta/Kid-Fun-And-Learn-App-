import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'settings_controller.dart';

/// Kid-safe settings: audio toggles + accessibility. Parent-only items
/// (account, data) live behind the parent gate in the Parent Dashboard.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final c = ref.read(settingsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _section(context, l10n.soundAndVoice),
          _toggle(
            context,
            l10n.soundEffects,
            Icons.graphic_eq_rounded,
            s.sfxEnabled,
            c.toggleSfx,
          ),
          _toggle(
            context,
            l10n.backgroundMusic,
            Icons.music_note_rounded,
            s.musicEnabled,
            c.toggleMusic,
          ),
          _toggle(
            context,
            l10n.voiceGuidance,
            Icons.record_voice_over_rounded,
            s.voiceEnabled,
            c.toggleVoice,
          ),
          _toggle(
            context,
            l10n.vibration,
            Icons.vibration_rounded,
            s.hapticsEnabled,
            c.toggleHaptics,
          ),
          _section(context, l10n.language),
          _languageSelector(context, s, c),
          _section(context, l10n.appearance),
          _themeSelector(context, s, c),
          _section(context, l10n.accessibility),
          _toggle(
            context,
            l10n.colorBlindFriendly,
            Icons.palette_rounded,
            s.colorBlindMode,
            c.toggleColorBlind,
          ),
          _toggle(
            context,
            l10n.biggerText,
            Icons.text_fields_rounded,
            s.largeText,
            c.toggleLargeText,
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _toggle(
    BuildContext context,
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, size: 30),
        title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        value: value,
        onChanged: onChanged,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      ),
    );
  }

  Widget _languageSelector(
    BuildContext context,
    SettingsState s,
    SettingsController c,
  ) {
    // (code, native label). Arabic renders right-to-left automatically via the
    // app's localization delegates.
    const langs = [
      ('en', 'English'),
      ('es', 'Español'),
      ('hi', 'हिन्दी'),
      ('ar', 'العربية'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (code, label) in langs)
              ChoiceChip(
                label: Text(label),
                selected: s.locale == code,
                onSelected: (_) => c.setLocale(code),
              ),
          ],
        ),
      ),
    );
  }

  Widget _themeSelector(
    BuildContext context,
    SettingsState s,
    SettingsController c,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final entry in {
              ThemeMode.light: Icons.wb_sunny_rounded,
              ThemeMode.dark: Icons.nightlight_round,
              ThemeMode.system: Icons.brightness_auto_rounded,
            }.entries)
              GestureDetector(
                onTap: () => c.setThemeMode(entry.key),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.themeMode == entry.key
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      ),
                      child: Icon(
                        entry.value,
                        size: 32,
                        color: s.themeMode == entry.key
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(entry.key.name),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
