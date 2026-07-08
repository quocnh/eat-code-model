import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated Pac-Man logo that "eats" the EatCode text.
///
/// The Pac-Man moves left-to-right across the title text.
/// As it passes each letter, the letter fades out (eaten).
/// After completing the sweep, the text fades back in and the cycle repeats.
///
/// Animation uses two controllers:
///   [_mouthController]  — mouth open/close (fast, 240 ms)
///   [_sweepController]  — Pac-Man position + letter eat (2.8 s cycle)
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
  late final Animation<double> _sweepProgress;

  @override
  void initState() {
    super.initState();

    // Mouth chomping — fast open/close cycle
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..repeat(reverse: true);

    _mouthAngle = Tween<double>(begin: 0.0, end: math.pi / 4.5).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    // Sweep: Pac-Man travels from left to right over 2.2 s, then 0.6 s pause
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Progress 0.0 → 1.0 drives both position and letter visibility
    _sweepProgress = CurvedAnimation(
      parent: _sweepController,
      curve: const Interval(0.0, 0.79, curve: Curves.easeInOut),
    );
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
        final sweep = _sweepProgress.value; // 0.0 → 1.0 as PacMan sweeps
        final mouth = _mouthAngle.value;    // current mouth open angle

        return _PacManTitleLayout(
          text: widget.text,
          textStyle: widget.textStyle,
          pacmanColor: widget.pacmanColor,
          sweepProgress: sweep,
          mouthAngle: mouth,
        );
      },
    );
  }
}

/// Lays out Pac-Man and the text characters.
/// Each character fades out when Pac-Man has passed it.
class _PacManTitleLayout extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color pacmanColor;
  final double sweepProgress; // 0.0 = far left, 1.0 = past last char
  final double mouthAngle;

  const _PacManTitleLayout({
    required this.text,
    required this.textStyle,
    required this.pacmanColor,
    required this.sweepProgress,
    required this.mouthAngle,
  });

  @override
  Widget build(BuildContext context) {
    const double pacSize = 22.0;
    const double charSpacing = 0.0;

    final effectiveStyle = (textStyle ?? const TextStyle()).copyWith(
      fontSize: textStyle?.fontSize ?? 18,
      fontWeight: textStyle?.fontWeight ?? FontWeight.bold,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Pac-Man body (moves left-to-right using padding trick) ──────────
        SizedBox(
          width: pacSize,
          height: pacSize,
          child: CustomPaint(
            painter: _PacManPainter(
              color: pacmanColor,
              mouthAngle: mouthAngle,
            ),
          ),
        ),

        const SizedBox(width: 6),

        // ── Individual letters, each fading as Pac-Man "eats" them ──────────
        ...List.generate(text.length, (i) {
          // Letter i is "eaten" when sweepProgress passes its position threshold
          final threshold = (i + 1) / (text.length + 1);
          final eaten = sweepProgress >= threshold;
          // Smooth fade-out as PacMan approaches
          final approachStart = (i / (text.length + 1)) - 0.05;
          final opacity = eaten
              ? 0.0
              : (sweepProgress > approachStart
                  ? 1.0 - ((sweepProgress - approachStart) / 0.12).clamp(0.0, 1.0)
                  : 1.0);

          return Padding(
            padding: EdgeInsets.only(right: charSpacing),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(
                text[i],
                style: effectiveStyle,
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Draws a classic Pac-Man circle with an animated chomping mouth.
class _PacManPainter extends CustomPainter {
  final Color color;
  final double mouthAngle; // 0 = closed, π/4 = wide open

  const _PacManPainter({required this.color, required this.mouthAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // The mouth opens symmetrically around the right-facing (0°) direction.
    // startAngle and sweepAngle define the arc NOT drawn (the mouth gap).
    final startAngle = mouthAngle;          // top jaw line
    final sweepAngle = 2 * math.pi - 2 * mouthAngle; // body arc

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

    // Eye — a small dark circle near the top
    final eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.2, center.dy - radius * 0.45),
      radius * 0.14,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(_PacManPainter old) =>
      old.mouthAngle != mouthAngle || old.color != color;
}
