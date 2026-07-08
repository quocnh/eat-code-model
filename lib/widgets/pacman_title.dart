import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Pac-Man logo that physically moves across 'EatCode'.
///
/// Cycle (5 s total):
///   0.00→0.40  Eat  — Pac-Man sweeps L→R, letters disappear
///   0.40→0.50  Pause at right
///   0.50→0.90  Return — Pac-Man sweeps R→L, letters reappear
///   0.90→1.00  Pause at left (reset)
class PacManTitle extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Color pacmanColor;

  const PacManTitle({
    super.key,
    this.text = 'EatCode',
    this.textStyle,
    this.pacmanColor = const Color(0xFFFDD835),
  });

  @override
  State<PacManTitle> createState() => _PacManTitleState();
}

class _PacManTitleState extends State<PacManTitle>
    with TickerProviderStateMixin {
  late final AnimationController _mouthController;
  late final AnimationController _sweepController;
  late final Animation<double> _mouthAngle;

  // Precomputed per-character layout
  late List<double> _charLeftEdges;
  late List<double> _charWidths;
  late TextStyle _effectiveStyle;
  late double _textWidth;

  static const double _pacSize = 22.0;
  static const double _gap = 6.0;

  @override
  void initState() {
    super.initState();
    _precomputeLayout();

    // Mouth chomps at 300 ms — slightly slower than before
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _mouthAngle = Tween<double>(begin: 0.0, end: math.pi / 4.5).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    // Full 5-second cycle
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
  }

  void _precomputeLayout() {
    _effectiveStyle = (widget.textStyle ?? const TextStyle()).copyWith(
      fontSize: widget.textStyle?.fontSize ?? 18,
      fontWeight: widget.textStyle?.fontWeight ?? FontWeight.bold,
    );

    _charLeftEdges = [];
    _charWidths = [];
    double x = 0;
    for (int i = 0; i < widget.text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: widget.text[i], style: _effectiveStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      _charLeftEdges.add(x);
      _charWidths.add(tp.width);
      x += tp.width;
    }
    _textWidth = x;
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mouthController, _sweepController]),
      builder: (context, _) {
        final t = _sweepController.value;
        final mouth = _mouthAngle.value;

        // ── Pac-Man position ──────────────────────────────────────────────
        final double startPacLeft = 0.0;
        final double endPacLeft = _gap + _textWidth;

        double pacLeft;
        bool facingLeft;

        if (t < 0.40) {
          final p = t / 0.40;
          pacLeft = startPacLeft + (endPacLeft - startPacLeft) * p;
          facingLeft = false;
        } else if (t < 0.50) {
          pacLeft = endPacLeft;
          facingLeft = false;
        } else if (t < 0.90) {
          final p = (t - 0.50) / 0.40;
          pacLeft = endPacLeft + (startPacLeft - endPacLeft) * p;
          facingLeft = true;
        } else {
          pacLeft = startPacLeft;
          facingLeft = false;
        }

        // ── Character opacities ───────────────────────────────────────────
        final n = widget.text.length;
        const fadeHalf = 0.06; // half-width of fade zone in progress units

        final charOpacities = List.generate(n, (i) {
          if (t >= 0.90) return 1.0; // pause-left: all visible

          // Eat: char i disappears at eatProgress ≈ (i + 0.5) / n
          final eatThreshold = (i + 0.5) / n;

          if (t < 0.50) {
            // Eating phase (or pause at right when eatProgress clamped to 1.0)
            final ep = t < 0.40 ? t / 0.40 : 1.0;
            if (ep >= eatThreshold + fadeHalf) return 0.0;
            if (ep <= eatThreshold - fadeHalf) return 1.0;
            return 1.0 -
                (ep - (eatThreshold - fadeHalf)) / (2 * fadeHalf);
          } else {
            // Return phase: rightmost chars reappear first
            final rp = (t - 0.50) / 0.40; // 0→1
            final returnThreshold = 1.0 - (i + 0.5) / n;
            if (rp >= returnThreshold + fadeHalf) return 1.0;
            if (rp <= returnThreshold - fadeHalf) return 0.0;
            return (rp - (returnThreshold - fadeHalf)) / (2 * fadeHalf);
          }
        });

        // ── Render ────────────────────────────────────────────────────────
        final totalWidth = _pacSize + _gap + _textWidth;

        return SizedBox(
          width: totalWidth,
          height: _pacSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Letters
              ...List.generate(n, (i) {
                return Positioned(
                  left: _pacSize + _gap + _charLeftEdges[i],
                  top: 0,
                  width: _charWidths[i],
                  height: _pacSize,
                  child: Opacity(
                    opacity: charOpacities[i].clamp(0.0, 1.0),
                    child: Center(
                      child: Text(widget.text[i], style: _effectiveStyle),
                    ),
                  ),
                );
              }),

              // Pac-Man — flipped horizontally on the return sweep
              Positioned(
                left: pacLeft,
                top: 0,
                width: _pacSize,
                height: _pacSize,
                child: Transform.scale(
                  scaleX: facingLeft ? -1.0 : 1.0,
                  child: CustomPaint(
                    painter: _PacManPainter(
                      color: widget.pacmanColor,
                      mouthAngle: mouth,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Classic Pac-Man shape with animated chomping mouth.
class _PacManPainter extends CustomPainter {
  final Color color;
  final double mouthAngle; // 0 = closed, π/4.5 = wide open

  const _PacManPainter({required this.color, required this.mouthAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Mouth opens symmetrically around the right-facing (0°) direction
    final startAngle = mouthAngle;
    final sweepAngle = 2 * math.pi - 2 * mouthAngle;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Eye — small dark circle near the top
    canvas.drawCircle(
      Offset(center.dx + radius * 0.2, center.dy - radius * 0.45),
      radius * 0.14,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PacManPainter old) =>
      old.mouthAngle != mouthAngle || old.color != color;
}
