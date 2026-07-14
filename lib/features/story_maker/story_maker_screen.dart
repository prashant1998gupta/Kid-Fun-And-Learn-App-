import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration_overlay.dart';
import '../gamification/domain/wallet.dart';
import '../art_studio/data/canvas_repository.dart';
import '../profiles/profiles_controller.dart';

/// Magic Story Maker — a create-your-own picture story.
///
/// The child picks a HERO, a PLACE and a magic THING; the app weaves a short
/// 4-page illustrated tale, reads it aloud, and lets them tap any word to hear
/// it on its own. Creative (they author it), fun (silly combos + narration),
/// and educational (early reading, vocabulary, story structure — beginning /
/// middle / end). Endless remixes, fully offline (TTS + emoji art).
class StoryMakerScreen extends ConsumerStatefulWidget {
  const StoryMakerScreen({super.key});

  @override
  ConsumerState<StoryMakerScreen> createState() => _StoryMakerScreenState();
}

enum _Phase { pickHero, pickPlace, pickThing, story }

class _Choice {
  const _Choice(this.emoji, this.word);
  final String emoji;
  final String word;
}

class _StoryMakerScreenState extends ConsumerState<StoryMakerScreen> {
  final _celebration = CelebrationController();

  _Phase _phase = _Phase.pickHero;
  _Choice? _hero;
  _Choice? _place;
  _Choice? _thing;
  int _page = 0;
  bool _rewarded = false;

  static const _heroes = [
    _Choice('🐼', 'Panda'),
    _Choice('🦁', 'Lion'),
    _Choice('🦄', 'Unicorn'),
    _Choice('🐰', 'Bunny'),
    _Choice('🐯', 'Tiger'),
    _Choice('🐧', 'Penguin'),
    _Choice('🐸', 'Frog'),
    _Choice('🦊', 'Fox'),
  ];

  List<_Choice> get _availableHeroes {
    final child = ref.read(activeChildProvider);
    final custom = child?.heroName;
    return [
      if (custom != null && custom.trim().isNotEmpty) _Choice('🎨', custom),
      ..._heroes,
    ];
  }

  static const _places = [
    _Choice('🌳', 'forest'),
    _Choice('🌊', 'ocean'),
    _Choice('🚀', 'space'),
    _Choice('🏰', 'castle'),
    _Choice('🏝️', 'island'),
    _Choice('🌈', 'rainbow land'),
    _Choice('🍭', 'candy world'),
    _Choice('🏔️', 'mountains'),
  ];
  static const _things = [
    _Choice('⭐', 'star'),
    _Choice('🔑', 'key'),
    _Choice('🎈', 'balloon'),
    _Choice('🪄', 'wand'),
    _Choice('💎', 'gem'),
    _Choice('🗺️', 'map'),
    _Choice('🎵', 'song'),
    _Choice('🧭', 'compass'),
  ];

  List<String> get _pages {
    final h = _hero!.word;
    final p = _place!.word;
    final t = _thing!.word;
    return [
      'Once upon a time, $h lived in the $p.',
      'One sunny day, $h found a magic $t!',
      '$h shared the $t with all the friends.',
      'Everyone laughed and played together. The End!',
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.speak("Let's make a story! Pick your hero.");
    });
  }

  void _choose(_Choice c) {
    AudioService.instance.playSfx(Sfx.pop);
    AudioService.instance.speak(c.word);
    setState(() {
      switch (_phase) {
        case _Phase.pickHero:
          _hero = c;
          _phase = _Phase.pickPlace;
          _speakPrompt('Now pick a place.');
        case _Phase.pickPlace:
          _place = c;
          _phase = _Phase.pickThing;
          _speakPrompt('Last, pick a magic thing!');
        case _Phase.pickThing:
          _thing = c;
          _phase = _Phase.story;
          _page = 0;
          _celebration.celebrate();
          WidgetsBinding.instance.addPostFrameCallback((_) => _readPage());
        case _Phase.story:
          break;
      }
    });
  }

  void _speakPrompt(String s) => WidgetsBinding.instance
      .addPostFrameCallback((_) => AudioService.instance.speak(s));

  void _readPage() => AudioService.instance.speak(_pages[_page]);

  Future<void> _nextPage() async {
    if (_page + 1 < _pages.length) {
      setState(() => _page++);
      _readPage();
      return;
    }
    // Finished the story — celebrate and reward once.
    _celebration.fireworks();
    AudioService.instance.speak('What a wonderful story! Well done!');
    if (!_rewarded) {
      _rewarded = true;
      await ref
          .read(profilesControllerProvider.notifier)
          .applyReward(const RewardBundle(coins: 15, xp: 12, stars: 1));
    }
    if (mounted) _showFinishSheet();
  }

  void _restart() {
    setState(() {
      _phase = _Phase.pickHero;
      _hero = null;
      _place = null;
      _thing = null;
      _page = 0;
      _rewarded = false;
    });
    _speakPrompt("Let's make another story! Pick your hero.");
  }

  void _showFinishSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final compact = media.size.width < 360 ||
            media.size.height < 620 ||
            media.textScaler.scale(1) > 1.25;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              compact ? AppSpacing.md : AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + media.viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: compact ? 42 : 56)),
                Text(
                  'Story complete!',
                  textAlign: TextAlign.center,
                  style: compact
                      ? Theme.of(sheetContext).textTheme.headlineSmall
                      : Theme.of(sheetContext).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'You earned 🪙 15 and a ⭐!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                BouncyButton(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _restart();
                  },
                  child: _pill('Make another! ✨', AppColors.secondary),
                ),
                const SizedBox(height: 10),
                BouncyButton(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).maybePop();
                  },
                  child: _pill('Done', AppColors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill(String label, Color color) => LayoutBuilder(
        builder: (context, constraints) => Container(
          width: math.min(260, constraints.maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        body: AnimatedBackground(
          theme: _phase == _Phase.story ? WorldTheme.sunrise : WorldTheme.candy,
          child: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: _phase == _Phase.story
                      ? _storyView(context)
                      : _pickerView(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final title = switch (_phase) {
      _Phase.pickHero => 'Pick your hero',
      _Phase.pickPlace => 'Pick a place',
      _Phase.pickThing => 'Pick a magic thing',
      _Phase.story => 'Your Story',
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Row(
            children: [
              BouncyButton(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.primary,
                    size: compact ? 23 : 26,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Text(
                  '📖 $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? Theme.of(context).textTheme.titleLarge
                          : Theme.of(context).textTheme.headlineMedium)
                      ?.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
              Wrap(
                spacing: 2,
                children: [
                  if (_hero != null)
                    Text(
                      _hero!.emoji,
                      style: TextStyle(fontSize: compact ? 20 : 24),
                    ),
                  if (_place != null)
                    Text(
                      _place!.emoji,
                      style: TextStyle(fontSize: compact ? 20 : 24),
                    ),
                  if (_thing != null)
                    Text(
                      _thing!.emoji,
                      style: TextStyle(fontSize: compact ? 20 : 24),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pickerView(BuildContext context) {
    final options = switch (_phase) {
      _Phase.pickHero => _availableHeroes,
      _Phase.pickPlace => _places,
      _Phase.pickThing => _things,
      _Phase.story => const <_Choice>[],
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: compact ? 170 : 210,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: compact ? 0.95 : 1.05,
            ),
            itemCount: options.length,
            itemBuilder: (context, i) => BouncyButton(
              borderRadius: AppSpacing.cardRadius,
              onTap: () => _choose(options[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(options[i].emoji,
                        style: TextStyle(fontSize: compact ? 48 : 60)),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      options[i].word,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 15 : 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightText,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (50 * i).ms)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          );
        },
      ),
    );
  }

  Widget _storyView(BuildContext context) {
    final sentence = _pages[_page];
    final words = sentence.split(' ');
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 300 || constraints.maxHeight < 430;
          final sceneWidth = constraints.maxWidth.clamp(220.0, 280.0);
          final sceneHeight = compact ? 160.0 : 200.0;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    key: ValueKey(_page),
                    width: sceneWidth,
                    height: sceneHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(child: _scene()),
                  )
                      .animate(key: ValueKey('scene$_page'))
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                      ),
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              Container(
                padding: compact
                    ? const EdgeInsets.all(AppSpacing.md)
                    : AppSpacing.cardPadding,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final w in words)
                      BouncyButton(
                        scaleTo: 0.85,
                        onTap: () => AudioService.instance
                            .speak(w.replaceAll(RegExp(r'[^A-Za-z]'), '')),
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: compact ? 20 : 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              Row(
                children: [
                  BouncyButton(
                    onTap: _readPage,
                    child: Container(
                      padding: EdgeInsets.all(compact ? 11 : 14),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.volume_up_rounded,
                          color: AppColors.primary, size: compact ? 26 : 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BouncyButton(
                      onTap: _nextPage,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: compact ? 14 : 16),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [AppColors.success, AppColors.mint]),
                          borderRadius: BorderRadius.all(AppSpacing.radiusPill),
                        ),
                        child: Text(
                          _page + 1 < _pages.length
                              ? 'Next page ➜'
                              : 'The End! 🎉',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Page ${_page + 1} of ${_pages.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _scene() {
    // Different arrangement per page keeps the pictures feeling like a story.
    final hero = _heroArt();
    final place = Text(_place!.emoji, style: const TextStyle(fontSize: 48));
    final thing = Text(_thing!.emoji, style: const TextStyle(fontSize: 48));
    switch (_page) {
      case 0: // hero in the place
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: 12, right: 24, child: place),
            hero,
          ],
        );
      case 1: // hero discovers the thing
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [hero, const SizedBox(width: 8), thing],
        );
      case 2: // hero shares — thing shining above
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [thing, hero],
        );
      default: // everyone happy
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hero,
            const Text('🎉', style: TextStyle(fontSize: 56)),
            place,
          ],
        );
    }
  }

  Widget _heroArt() {
    final child = ref.read(activeChildProvider);
    if (_hero?.emoji == '🎨' && child?.heroDrawingId != null) {
      for (final drawing in ref.read(canvasRepositoryProvider).loadAll()) {
        if (drawing.id == child!.heroDrawingId) {
          return Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.memory(drawing.thumbnailBytes, fit: BoxFit.contain),
          );
        }
      }
    }
    return Text(_hero!.emoji, style: const TextStyle(fontSize: 84));
  }
}
