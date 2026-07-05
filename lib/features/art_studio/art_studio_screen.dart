import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/bouncy_button.dart';
import '../profiles/profiles_controller.dart';
import 'data/canvas_repository.dart';

/// Art Studio — a creative free-draw canvas like Khan Academy Kids.
///
/// Tools: pen (12 colors + 4 sizes), fill bucket, eraser, undo, trace templates
/// (A-Z, a-z, 0-9, shapes), save to gallery.
class ArtStudioScreen extends ConsumerStatefulWidget {
  const ArtStudioScreen({super.key});

  @override
  ConsumerState<ArtStudioScreen> createState() => _ArtStudioState();
}

/// A single stroke on the canvas.
class _Stroke {
  _Stroke({
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
}

/// A trace template definition.
class _TraceTemplate {
  const _TraceTemplate(this.label, this.category, this.glyph);
  final String label;
  final String category; // 'letter', 'number', 'shape'
  final String glyph;
}

class _ArtStudioState extends ConsumerState<ArtStudioScreen> {
  final _uuid = const Uuid();
  final GlobalKey _repaintKey = GlobalKey();

  // Drawing state
  final List<_Stroke> _strokes = [];
  final List<Offset> _currentStroke = [];
  Color _currentColor = AppColors.primary;
  double _penWidth = 12;
  bool _isEraser = false;
  bool _fillMode = false;
  bool _showTracePicker = false;
  _TraceTemplate? _activeTrace;

  // The rendered canvas size (from RepaintBoundary).
  Size _canvasSize = Size.zero;

  /// Triggers repaint of just the canvas (no full widget rebuild).
  final _canvasPaintNotifier = ValueNotifier<int>(0);

  // All 12 colors
  static const _colors = [
    Color(0xFFE74C3C), // Red
    Color(0xFFF39C12), // Orange
    Color(0xFFF1C40F), // Yellow
    Color(0xFF2ECC71), // Green
    Color(0xFF1ABC9C), // Teal
    Color(0xFF3498DB), // Blue
    Color(0xFF9B59B6), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF8B4513), // Brown
    Color(0xFF2C3E50), // Dark
    Colors.white, // White
    AppColors.primary, // Violet
  ];

  static const _penSizes = [6.0, 12.0, 24.0, 40.0];

  // Trace templates
  static final _traceTemplates = [
    // Uppercase A-Z
    for (final c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
      _TraceTemplate(c, 'Letters', c),
    // Lowercase a-z
    for (final c in 'abcdefghijklmnopqrstuvwxyz'.split(''))
      _TraceTemplate(c, 'Letters', c),
    // Numbers 0-9
    for (final c in '0123456789'.split('')) _TraceTemplate(c, 'Numbers', c),
    // Shapes
    const _TraceTemplate('Circle', 'Shapes', '○'),
    const _TraceTemplate('Square', 'Shapes', '□'),
    const _TraceTemplate('Triangle', 'Shapes', '△'),
    const _TraceTemplate('Star', 'Shapes', '★'),
    const _TraceTemplate('Heart', 'Shapes', '♥'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        theme: WorldTheme.candy,
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              if (_showTracePicker)
                _traceTemplatePicker()
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: _canvas(),
                  ),
                ),
              _toolBar(),
              if (!_showTracePicker) _bottomToolBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '🎨 Art Studio',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          // Undo
          _iconBtn(Icons.undo_rounded, 'Undo', _undo,
              disabled: _strokes.isEmpty),
          const SizedBox(width: 6),
          // Clear
          _iconBtn(Icons.delete_sweep_rounded, 'Clear', _confirmClear),
          const SizedBox(width: 6),
          // Save
          _iconBtn(Icons.save_rounded, 'Save', _save),
          const SizedBox(width: 6),
          // Gallery
          _iconBtn(
              Icons.photo_library_rounded,
              'Gallery',
              () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _GalleryScreen()),
                  )),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap,
      {bool disabled = false}) {
    return BouncyButton(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: disabled ? Colors.white38 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: disabled ? Colors.grey : AppColors.primary, size: 22),
      ),
    );
  }

  // ─── Canvas ───────────────────────────────────────────────────────

  Widget _canvas() {
    return ClipRRect(
      borderRadius: AppSpacing.cardRadius,
      child: RepaintBoundary(
        key: _repaintKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onPanStart: (d) => _startStroke(d.localPosition),
              onPanUpdate: (d) => _extendStroke(d.localPosition),
              onPanEnd: (_) => _endStroke(),
              child: ValueListenableBuilder<int>(
                valueListenable: _canvasPaintNotifier,
                builder: (context, _, __) => CustomPaint(
                  painter: _CanvasPainter(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    currentColor: _isEraser ? Colors.white : _currentColor,
                    currentWidth: _penWidth,
                    isEraser: _isEraser,
                    trace: _activeTrace,
                    canvasSize: _canvasSize,
                  ),
                  size: _canvasSize,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Drawing logic ───────────────────────────────────────────────

  void _startStroke(Offset pos) {
    _currentStroke.clear();
    _currentStroke.add(pos);
    _canvasPaintNotifier.value++;
  }

  void _extendStroke(Offset pos) {
    _currentStroke.add(pos);
    // Only repaint the canvas, not the whole widget tree.
    _canvasPaintNotifier.value++;
  }

  void _endStroke() {
    if (_currentStroke.length < 2) {
      if (_fillMode) {
        // Fill mode: treat a tap as fill command.
        // We just add a filled rect covering the whole canvas as a filled layer.
        setState(() {
          _strokes.add(_Stroke(
            points: [const Offset(-1, -1)], // marker for fill
            color: _currentColor,
            width: _canvasSize.width * 2,
            isEraser: false,
          ));
        });
      }
      _currentStroke.clear();
      return;
    }
    _strokes.add(_Stroke(
      points: List.from(_currentStroke),
      color: _isEraser ? Colors.white : _currentColor,
      width: _penWidth,
      isEraser: _isEraser,
    ));
    _currentStroke.clear();
    _canvasPaintNotifier.value++;
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _canvasPaintNotifier.value++;
    AudioService.instance.playSfx(Sfx.pop);
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear drawing?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _strokes.clear();
              _canvasPaintNotifier.value++;
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final repo = ref.read(canvasRepositoryProvider);
      final drawings = repo.loadAll();
      final drawing = SavedDrawing(
        id: _uuid.v4(),
        name: 'Drawing ${drawings.length + 1}',
        thumbnailBytes: bytes,
        createdAt: DateTime.now(),
      );
      drawings.insert(0, drawing);
      await repo.saveAll(drawings);
      AudioService.instance.playSfx(Sfx.reward);
      if (!mounted) return;
      await _offerAsHero(drawing);
    } catch (_) {}
  }

  Future<void> _offerAsHero(SavedDrawing drawing) async {
    final controller = TextEditingController(text: 'My Magic Hero');
    var listening = false;
    final chosen = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('✨ Bring your drawing to life?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                child: Image.memory(drawing.thumbnailBytes),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Name your hero',
                  suffixIcon: IconButton(
                    tooltip: 'Say the name',
                    icon: Icon(listening ? Icons.mic : Icons.mic_none_rounded),
                    onPressed: () async {
                      final ready = await SpeechService.instance.ensureReady();
                      if (!ready || !dialogContext.mounted) return;
                      setDialogState(() => listening = true);
                      await SpeechService.instance.listen(
                        onResult: (words, _) {
                          if (words.trim().isNotEmpty) controller.text = words;
                        },
                        onDone: () {
                          if (dialogContext.mounted) {
                            setDialogState(() => listening = false);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Just save it'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                controller.text.trim().isEmpty
                    ? 'My Magic Hero'
                    : controller.text.trim(),
              ),
              child: const Text('Make it my hero!'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (chosen == null || !mounted) return;
    await ref
        .read(profilesControllerProvider.notifier)
        .chooseDrawingHero(drawing.id, chosen);
    AudioService.instance.speak('$chosen now lives in your world!');
  }

  // ─── Tool bar (colors + pen sizes) ───────────────────────────────

  Widget _toolBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final color in _colors)
                  GestureDetector(
                    onTap: () => setState(() {
                      _currentColor = color;
                      _isEraser = false;
                      _fillMode = false;
                    }),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentColor == color && !_isEraser
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (color == Colors.white)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Pen sizes row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final size in _penSizes)
                  GestureDetector(
                    onTap: () => setState(() {
                      _penWidth = size;
                      _isEraser = false;
                      _fillMode = false;
                    }),
                    child: Container(
                      width: 48,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _penWidth == size && !_isEraser
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _penWidth == size && !_isEraser
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: size.clamp(4, 30),
                          height: size.clamp(4, 30),
                          decoration: BoxDecoration(
                            color: _currentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom tool bar ──────────────────────────────────────────────

  Widget _bottomToolBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(Icons.draw_rounded, 'Pen',
              !_isEraser && !_fillMode && !_showTracePicker),
          _toolBtn(Icons.format_paint_rounded, 'Fill', _fillMode),
          _toolBtn(Icons.auto_fix_high_rounded, 'Trace', _showTracePicker),
          _toolBtn(Icons.auto_fix_high_rounded, 'Eraser', _isEraser),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, bool active) {
    return BouncyButton(
      onTap: () => setState(() {
        _showTracePicker = false;
        _fillMode = false;
        _isEraser = false;
        if (label == 'Trace') {
          _showTracePicker = true;
        } else if (label == 'Fill') {
          _fillMode = true;
        } else if (label == 'Eraser') {
          _isEraser = true;
        }
        // 'Pen' is the default — all false
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border:
              active ? Border.all(color: AppColors.primary, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: active ? AppColors.primary : AppColors.lightText),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trace template picker ────────────────────────────────────────

  Widget _traceTemplatePicker() {
    final cats = {'Letters': '🔤', 'Numbers': '🔢', 'Shapes': '🔶'};
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (final entry in cats.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Row(
                  children: [
                    Text('${entry.value} ${entry.key}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in _traceTemplates
                        .where((t) => t.category == entry.key))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: BouncyButton(
                          onTap: () => setState(() {
                            _activeTrace = t;
                            _showTracePicker = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              t.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_activeTrace != null &&
                        entry.key == (_activeTrace?.category ?? ''))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: BouncyButton(
                          onTap: () => setState(() => _activeTrace = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              '✕ Remove',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Canvas Painter ──────────────────────────────────────────────────

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
    required this.isEraser,
    required this.trace,
    required this.canvasSize,
  });

  final List<_Stroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;
  final bool isEraser;
  final _TraceTemplate? trace;
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything inside saveLayer so BlendMode.clear shows white background.
    canvas.saveLayer(Offset.zero & size, Paint());

    // White background base
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Draw trace template if active
    if (trace != null) {
      final text = trace!.glyph;
      final fontSize = size.height * 0.5;
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2,
          (size.height - tp.height) / 2,
        ),
      );
    }

    // ── Draw all completed strokes ──
    for (final stroke in strokes) {
      if (stroke.points.length == 1 &&
          stroke.points.first == const Offset(-1, -1)) {
        // Fill command — draw a filled rect
        canvas.drawRect(
            Offset.zero & size,
            Paint()
              ..color = stroke.color.withValues(alpha: 0.3)
              ..style = PaintingStyle.fill);
        continue;
      }
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.white : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = _smoothPath(stroke.points);
      if (path != null) {
        if (!stroke.isEraser) {
          // Glow
          canvas.drawPath(
              path,
              Paint()
                ..color = stroke.color.withValues(alpha: 0.2)
                ..strokeWidth = stroke.width + 8
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke);
        }
        if (stroke.isEraser) {
          // Truly erase by clearing pixels (reveals white background below)
          canvas.drawPath(
              path,
              Paint()
                ..blendMode = BlendMode.clear
                ..strokeWidth = stroke.width + 4
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke);
        } else {
          canvas.drawPath(path, paint);
        }
      }
    }

    // ── Draw the in-progress stroke ON TOP (real-time as finger moves) ──
    if (currentStroke.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = _smoothPath(currentStroke);
      if (path != null) {
        if (!isEraser) {
          // Glow for pen mode
          canvas.drawPath(
              path,
              Paint()
                ..color = currentColor.withValues(alpha: 0.2)
                ..strokeWidth = currentWidth + 8
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke);
        }
        if (isEraser) {
          // Eraser clears to white background (both inside saveLayer)
          canvas.drawPath(
              path,
              Paint()
                ..blendMode = BlendMode.clear
                ..strokeWidth = currentWidth + 4
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..style = PaintingStyle.stroke);
        } else {
          canvas.drawPath(path, paint);
        }
      }
    }

    canvas.restore();
  }

  Path? _smoothPath(List<Offset> pts) {
    if (pts.length < 2) return null;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.strokes.length != strokes.length ||
      old.currentStroke.length != currentStroke.length ||
      old.currentColor != currentColor ||
      old.currentWidth != currentWidth ||
      old.isEraser != isEraser ||
      old.trace != trace;
}

// ─── Gallery Screen (embedded) ──────────────────────────────────────

class _GalleryScreen extends ConsumerWidget {
  const _GalleryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(canvasRepositoryProvider);
    final drawings = repo.loadAll();

    return Scaffold(
      appBar: AppBar(title: const Text('🖼️ My Gallery')),
      body: drawings.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎨', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('No drawings yet!\nDraw something and save it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: drawings.length,
              itemBuilder: (context, i) {
                final d = drawings[i];
                return GestureDetector(
                  onTap: () => _viewFull(context, ref, d),
                  onLongPress: () => _confirmDelete(context, ref, d),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: Image.memory(d.thumbnailBytes,
                                fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(d.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewFull(BuildContext context, WidgetRef ref, SavedDrawing d) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(d.name)),
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    child: Image.memory(d.thumbnailBytes),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(profilesControllerProvider.notifier)
                        .chooseDrawingHero(d.id, d.name);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Use as my story hero'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SavedDrawing d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete drawing?'),
        content: Text('Delete "${d.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(canvasRepositoryProvider).delete(d.id);
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
