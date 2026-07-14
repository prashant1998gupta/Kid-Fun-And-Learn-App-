import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../../core/widgets/celebration_overlay.dart';
import '../../core/widgets/illustrated_object.dart';
import '../../core/widgets/openmoji_view.dart';
import '../profiles/profiles_controller.dart';
import 'preschool_practice_catalog.dart';
import 'preschool_practice_controller.dart';

class PreschoolPracticeScreen extends ConsumerWidget {
  const PreschoolPracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    if (child == null || !PreschoolPracticeCatalog.availableFor(child.grade)) {
      return const _UnavailablePracticeScreen();
    }
    final tracing = PreschoolPracticeCategory.values
        .where((category) => category.kind == PreschoolPracticeKind.trace);
    final words = PreschoolPracticeCategory.values
        .where((category) => category.kind == PreschoolPracticeKind.vocabulary);

    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              const SliverToBoxAdapter(
                child: _WelcomeCard(),
              ),
              _sectionTitle('✍️ Learn & Trace'),
              _categoryGrid(context, child.id, tracing),
              _sectionTitle('🗣️ Picture Words'),
              _categoryGrid(context, child.id, words),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Row(
              children: [
                BouncyButton(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: CircleAvatar(
                    radius: compact ? 18 : 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: compact ? 22 : 24,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  child: Text(
                    'My Learn & Trace Library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 20 : 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text('🖍️', style: TextStyle(fontSize: compact ? 32 : 40)),
              ],
            );
          },
        ),
      );

  SliverToBoxAdapter _sectionTitle(String title) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

  Widget _categoryGrid(
    BuildContext context,
    String childId,
    Iterable<PreschoolPracticeCategory> categories,
  ) {
    final list = categories.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.crossAxisExtent < 360;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: compact ? 190 : 240,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: compact ? 0.78 : 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = list[index];
                return _CategoryProgressCard(
                  category: category,
                  childId: childId,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PreschoolCategoryScreen(
                        category: category,
                        childId: childId,
                      ),
                    ),
                  ),
                );
              },
              childCount: list.length,
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatefulWidget {
  const _WelcomeCard();

  @override
  State<_WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<_WelcomeCard> {
  static const message =
      'Choose anything you want. Hear it, see it, and practise it as many times as you like!';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => AudioService.instance.speak(message),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: EdgeInsets.all(compact ? 13 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Text('🦉', style: TextStyle(fontSize: compact ? 40 : 52)),
                SizedBox(width: compact ? 9 : 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: compact ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 14 : 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hear this',
                  onPressed: () => AudioService.instance.speak(message),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _CategoryProgressCard extends ConsumerWidget {
  const _CategoryProgressCard({
    required this.category,
    required this.childId,
    required this.onTap,
  });

  final PreschoolPracticeCategory category;
  final String childId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = PreschoolPracticeCatalog.idsFor(category);
    final practised = ref.watch(
      preschoolPracticeControllerProvider(childId).select(
        (state) => state.practisedCount(ids),
      ),
    );
    return _CategoryCard(
      category: category,
      progress: ids.isEmpty ? 0 : practised / ids.length,
      practised: practised,
      total: ids.length,
      onTap: onTap,
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.progress,
    required this.practised,
    required this.total,
    required this.onTap,
  });

  final PreschoolPracticeCategory category;
  final double progress;
  final int practised;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxHeight < 170 || constraints.maxWidth < 170;
          return BouncyButton(
            key: ValueKey('preschool-category-${category.id}'),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(compact ? 9 : 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.cardRadius,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(category.emoji,
                      style: TextStyle(fontSize: compact ? 28 : 38)),
                  SizedBox(height: compact ? 3 : 5),
                  Text(
                    category.title,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.lightText,
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 14 : 17,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: compact ? 6 : 8,
                    borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                    color: AppColors.success,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  SizedBox(height: compact ? 3 : 4),
                  Text(
                    '$practised of $total explored',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.lightTextSoft,
                      fontSize: compact ? 10 : 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class PreschoolCategoryScreen extends ConsumerStatefulWidget {
  const PreschoolCategoryScreen({
    required this.category,
    required this.childId,
    super.key,
  });

  final PreschoolPracticeCategory category;
  final String childId;

  @override
  ConsumerState<PreschoolCategoryScreen> createState() =>
      _PreschoolCategoryScreenState();
}

class _PreschoolCategoryScreenState
    extends ConsumerState<PreschoolCategoryScreen> {
  static const _initialArtPrecacheCount = 12;
  bool _didPrecacheArt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheArt) return;
    _didPrecacheArt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Warm only the first visible-ish batch. Preloading all 30 images at
      // once makes category entry heavier on low-memory phones; the detail
      // screen still preloads nearby next/previous words for smooth swiping.
      final paths = <String>{
        for (final item in PreschoolPracticeCatalog.itemsFor(widget.category)
            .take(_initialArtPrecacheCount))
          if (OpenMojiView.assetPathFor(item.emoji) case final path?) path,
      };
      for (final path in paths) {
        precacheImage(AssetImage(path), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = PreschoolPracticeCatalog.itemsFor(widget.category);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.emoji} ${widget.category.title}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              widget.category.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Everything is always open. Choose any one! 🌟'),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _ItemCard(
                  item: item,
                  childId: widget.childId,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PreschoolLearnScreen(
                        items: items,
                        initialIndex: index,
                        childId: widget.childId,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({
    required this.item,
    required this.childId,
    required this.onTap,
  });

  final PreschoolPracticeItem item;
  final String childId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(
      preschoolPracticeControllerProvider(childId).select(
        (state) => state.forItem(item.id).stage,
      ),
    );
    final color = switch (stage) {
      PreschoolPracticeStage.newItem => AppColors.info,
      PreschoolPracticeStage.practising => AppColors.warning,
      PreschoolPracticeStage.great => AppColors.success,
    };
    return BouncyButton(
      key: ValueKey('preschool-item-${item.id}'),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.glyph == null)
                IllustratedObjectView(
                  label: item.name,
                  emoji: item.emoji,
                  size: 62,
                )
              else ...[
                Text(item.glyph!,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    )),
                IllustratedObjectView(
                  label: item.example ?? item.name,
                  emoji: item.emoji,
                  size: 30,
                ),
              ],
              Text(
                item.example ?? item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
                ),
                child: Text(stage.label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreschoolLearnScreen extends ConsumerStatefulWidget {
  const PreschoolLearnScreen({
    required this.items,
    required this.initialIndex,
    required this.childId,
    super.key,
  });

  final List<PreschoolPracticeItem> items;
  final int initialIndex;
  final String childId;

  @override
  ConsumerState<PreschoolLearnScreen> createState() =>
      _PreschoolLearnScreenState();
}

class _PreschoolLearnScreenState extends ConsumerState<PreschoolLearnScreen> {
  late int _index = widget.initialIndex;

  PreschoolPracticeItem get _item => widget.items[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheNearbyArt();
      _visitAndSpeak();
    });
  }

  Future<void> _visitAndSpeak() async {
    final item = _item;
    await ref
        .read(preschoolPracticeControllerProvider(widget.childId).notifier)
        .viewed(item.id);
    if (!mounted) return;
    await AudioService.instance
        .speak(item.spoken, language: item.voiceLanguage);
  }

  void _move(int delta) {
    setState(() {
      _index = (_index + delta) % widget.items.length;
      if (_index < 0) _index += widget.items.length;
    });
    _precacheNearbyArt();
    _visitAndSpeak();
  }

  void _precacheNearbyArt() {
    if (!mounted || widget.items.isEmpty) return;
    final paths = <String>{};
    for (final offset in const [-2, -1, 0, 1, 2]) {
      final item = widget.items[(_index + offset) % widget.items.length];
      if (OpenMojiView.assetPathFor(item.emoji) case final path?) {
        paths.add(path);
      }
    }
    for (final path in paths) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final stage = ref.watch(
      preschoolPracticeControllerProvider(widget.childId).select(
        (state) => state.forItem(item.id).stage,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(item.category.title),
        actions: [
          IconButton(
            tooltip: 'Hear again',
            onPressed: () => AudioService.instance
                .speak(item.spoken, language: item.voiceLanguage),
            icon: const Icon(Icons.volume_up_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: LinearProgressIndicator(
                value: (_index + 1) / widget.items.length,
                minHeight: 10,
                borderRadius: const BorderRadius.all(AppSpacing.radiusPill),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (item.glyph == null)
                        IllustratedObjectView(
                          label: item.name,
                          emoji: item.emoji,
                          size: 148,
                        )
                      else ...[
                        Text(
                          item.glyph!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 116,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IllustratedObjectView(
                          label: item.example ?? item.name,
                          emoji: item.emoji,
                          size: 92,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        item.example ?? item.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stage.label,
                        style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey('practice-hear-again'),
                            onPressed: () => AudioService.instance.speak(
                                item.spoken,
                                language: item.voiceLanguage),
                            icon: const Icon(Icons.volume_up_rounded),
                            label: const Text('Hear Again'),
                          ),
                          if (item.traceable)
                            FilledButton.icon(
                              key: const ValueKey('practice-open-trace'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.secondary),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PreschoolTraceScreen(
                                    item: item,
                                    childId: widget.childId,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.draw_rounded),
                              label: const Text('Trace It'),
                            )
                          else
                            FilledButton.icon(
                              key: const ValueKey('practice-learned-word'),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success),
                              onPressed: () async {
                                await ref
                                    .read(preschoolPracticeControllerProvider(
                                            widget.childId)
                                        .notifier)
                                    .practised(item.id);
                                AudioService.instance.speak('Great learning!');
                              },
                              icon: const Icon(Icons.star_rounded),
                              label: const Text('I Learned It'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreschoolTraceScreen extends ConsumerStatefulWidget {
  const PreschoolTraceScreen({
    required this.item,
    required this.childId,
    super.key,
  });

  final PreschoolPracticeItem item;
  final String childId;

  @override
  ConsumerState<PreschoolTraceScreen> createState() =>
      _PreschoolTraceScreenState();
}

class _PreschoolTraceScreenState extends ConsumerState<PreschoolTraceScreen>
    with SingleTickerProviderStateMixin {
  final _celebration = CelebrationController();
  final List<List<Offset>> _strokes = [];
  late final AnimationController _guideAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _showGuide = true;
  bool _finishing = false;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncGuideAnimation();
      AudioService.instance.speak(
        '${widget.item.spoken}. Start at the green dot and follow the shape.',
        language: widget.item.voiceLanguage,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGuideAnimation();
  }

  @override
  void dispose() {
    _guideAnimation.dispose();
    super.dispose();
  }

  void _start(Offset point) => setState(() {
        _strokes.add([point]);
        _points++;
        _syncGuideAnimation();
      });

  void _draw(Offset point) {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.last.add(point);
      _points++;
    });
  }

  void _clear() => setState(() {
        _strokes.clear();
        _points = 0;
        _syncGuideAnimation();
      });

  void _syncGuideAnimation() {
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimateGuide = _showGuide && _strokes.isEmpty && !reducedMotion;
    if (shouldAnimateGuide && !_guideAnimation.isAnimating) {
      _guideAnimation.repeat(reverse: true);
    } else if (!shouldAnimateGuide && _guideAnimation.isAnimating) {
      _guideAnimation.stop();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref
        .read(preschoolPracticeControllerProvider(widget.childId).notifier)
        .practised(widget.item.id);
    if (!mounted) return;
    _celebration.celebrate();
    AudioService.instance
        .speak('Wonderful tracing! You can do it again anytime.');
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final compact = media.size.width < 360 ||
            media.size.height < 620 ||
            media.textScaler.scale(1) > 1.25;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 24,
              compact ? 18 : 24,
              compact ? 18 : 24,
              (compact ? 18 : 24) + media.viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌟', style: TextStyle(fontSize: compact ? 44 : 58)),
                Text(
                  'Beautiful practice!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 21 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('trace-again'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _clear();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Again'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('trace-choose-another'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Another'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationOverlay(
      controller: _celebration,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Trace ${widget.item.glyph}'),
          actions: [
            IconButton(
              tooltip: 'Hear again',
              onPressed: () => AudioService.instance.speak(widget.item.spoken,
                  language: widget.item.voiceLanguage),
              icon: const Icon(Icons.volume_up_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showGuide
                            ? 'Start at the green dot. Follow the shape.'
                            : 'Free draw! Make it your own way.',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilterChip(
                      key: const ValueKey('free-draw-toggle'),
                      selected: !_showGuide,
                      label: const Text('Free Draw'),
                      onSelected: (free) => setState(() {
                        _showGuide = !free;
                        _syncGuideAnimation();
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    key: const ValueKey('preschool-trace-canvas'),
                    onPanStart: (details) => _start(details.localPosition),
                    onPanUpdate: (details) => _draw(details.localPosition),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.cardRadius,
                        boxShadow: [
                          BoxShadow(color: Color(0x22000000), blurRadius: 16),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _PreschoolTracePainter(
                          glyph: widget.item.glyph!,
                          strokes: _strokes,
                          showGuide: _showGuide,
                          guideAnimation: _guideAnimation,
                          revision: _points,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clear,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('finish-tracing'),
                        onPressed: _points < 12 || _finishing ? null : _finish,
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('I Finished'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreschoolTracePainter extends CustomPainter {
  _PreschoolTracePainter({
    required this.glyph,
    required this.strokes,
    required this.showGuide,
    required this.guideAnimation,
    required this.revision,
  }) : super(repaint: guideAnimation);

  final String glyph;
  final List<List<Offset>> strokes;
  final bool showGuide;
  final Animation<double> guideAnimation;
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = size.shortestSide * (glyph.length > 1 ? 0.62 : 0.76);
    final textPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = showGuide ? PaintingStyle.stroke : PaintingStyle.fill
            ..strokeWidth = 5
            ..color = showGuide
                ? AppColors.primary.withValues(alpha: 0.38)
                : AppColors.primary.withValues(alpha: 0.04),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final glyphOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, glyphOffset);

    if (showGuide && strokes.isEmpty) {
      final pulse = 9 + guideAnimation.value * 4;
      final start = Offset(
        glyphOffset.dx + textPainter.width * 0.18,
        glyphOffset.dy + textPainter.height * 0.18,
      );
      canvas.drawCircle(start, pulse, Paint()..color = AppColors.success);
      final label = TextPainter(
        text: const TextSpan(
          text: '1',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, start - Offset(label.width / 2, label.height / 2));
    }

    final glow = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.2)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final ink = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _PreschoolTracePainter oldDelegate) =>
      oldDelegate.revision != revision ||
      oldDelegate.showGuide != showGuide ||
      oldDelegate.glyph != glyph;
}

class _UnavailablePracticeScreen extends StatelessWidget {
  const _UnavailablePracticeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'This playful practice library is designed for LKG, UKG and KG profiles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
}
