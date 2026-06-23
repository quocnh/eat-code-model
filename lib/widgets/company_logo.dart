import 'package:flutter/material.dart';

/// Renders a recognizable, brand-coloured logo badge for a tech company.
///
/// Avoids external network dependencies and binary assets by composing the
/// logo from Material widgets, brand colours, and stylized initials. The
/// result is a circular badge that visually identifies each company without
/// relying on emoji rendering (which varies across platforms).
class CompanyLogo extends StatelessWidget {
  final String company;
  final double size;

  const CompanyLogo({
    super.key,
    required this.company,
    this.size = 44,
  });

  // Brand palette — sourced from public brand guidelines.
  static const Map<String, _BrandSpec> _brands = {
    'Google': _BrandSpec(
      // Google's signature "G" uses 4 colors. We render a multi-arc effect.
      backgroundColor: Colors.white,
      borderColor: Color(0xFFE0E0E0),
      foregroundColor: Color(0xFF4285F4),
      letter: 'G',
      kind: _LogoKind.googleG,
    ),
    'Amazon': _BrandSpec(
      backgroundColor: Color(0xFF232F3E),
      foregroundColor: Color(0xFFFF9900),
      letter: 'a',
      kind: _LogoKind.amazon,
    ),
    'Meta': _BrandSpec(
      backgroundColor: Colors.white,
      borderColor: Color(0xFFE0E0E0),
      foregroundColor: Color(0xFF0866FF),
      letter: '∞',
      kind: _LogoKind.meta,
    ),
    'Microsoft': _BrandSpec(
      backgroundColor: Colors.white,
      borderColor: Color(0xFFE0E0E0),
      foregroundColor: Color(0xFF737373),
      letter: '',
      kind: _LogoKind.microsoftSquares,
    ),
    'Apple': _BrandSpec(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Colors.white,
      letter: '',
      kind: _LogoKind.appleIcon,
    ),
    'Netflix': _BrandSpec(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFE50914),
      letter: 'N',
      kind: _LogoKind.netflixN,
    ),
    'Uber': _BrandSpec(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Colors.white,
      letter: 'Uber',
      kind: _LogoKind.uberWord,
    ),
    'Airbnb': _BrandSpec(
      backgroundColor: Color(0xFFFF5A5F),
      foregroundColor: Colors.white,
      letter: '',
      kind: _LogoKind.airbnbBelo,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = _brands[company] ??
        const _BrandSpec(
          backgroundColor: Color(0xFFE0E0E0),
          foregroundColor: Color(0xFF424242),
          letter: '?',
          kind: _LogoKind.letter,
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        shape: BoxShape.circle,
        border: spec.borderColor != null
            ? Border.all(color: spec.borderColor!, width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _renderBrand(spec),
    );
  }

  Widget _renderBrand(_BrandSpec spec) {
    switch (spec.kind) {
      case _LogoKind.appleIcon:
        return Center(
          child: Icon(
            Icons.apple,
            color: spec.foregroundColor,
            size: size * 0.62,
          ),
        );
      case _LogoKind.microsoftSquares:
        return Center(
          child: SizedBox(
            width: size * 0.55,
            height: size * 0.55,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ColoredBox(color: Color(0xFFF25022)), // red
                ColoredBox(color: Color(0xFF7FBA00)), // green
                ColoredBox(color: Color(0xFF00A4EF)), // blue
                ColoredBox(color: Color(0xFFFFB900)), // yellow
              ],
            ),
          ),
        );
      case _LogoKind.googleG:
        return CustomPaint(
          size: Size(size, size),
          painter: _GoogleGPainter(),
        );
      case _LogoKind.amazon:
        return Stack(
          alignment: Alignment.center,
          children: [
            Text(
              spec.letter,
              style: TextStyle(
                fontSize: size * 0.58,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            Positioned(
              bottom: size * 0.18,
              child: CustomPaint(
                size: Size(size * 0.45, size * 0.18),
                painter: _AmazonSmilePainter(color: spec.foregroundColor),
              ),
            ),
          ],
        );
      case _LogoKind.meta:
        return Center(
          child: Text(
            spec.letter,
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.w900,
              color: spec.foregroundColor,
              height: 1.0,
            ),
          ),
        );
      case _LogoKind.netflixN:
        return Center(
          child: Text(
            spec.letter,
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w900,
              color: spec.foregroundColor,
              fontStyle: FontStyle.italic,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
        );
      case _LogoKind.uberWord:
        return Center(
          child: Text(
            spec.letter,
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.w900,
              color: spec.foregroundColor,
              letterSpacing: -0.5,
            ),
          ),
        );
      case _LogoKind.airbnbBelo:
        return Center(
          child: CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: _AirbnbBeloPainter(color: spec.foregroundColor),
          ),
        );
      case _LogoKind.letter:
        return Center(
          child: Text(
            spec.letter,
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.w800,
              color: spec.foregroundColor,
            ),
          ),
        );
    }
  }
}

enum _LogoKind {
  letter,
  appleIcon,
  microsoftSquares,
  googleG,
  amazon,
  meta,
  netflixN,
  uberWord,
  airbnbBelo,
}

class _BrandSpec {
  final Color backgroundColor;
  final Color? borderColor;
  final Color foregroundColor;
  final String letter;
  final _LogoKind kind;

  const _BrandSpec({
    required this.backgroundColor,
    this.borderColor,
    required this.foregroundColor,
    required this.letter,
    required this.kind,
  });
}

// ---------------------------------------------------------------------------
// Custom painters
// ---------------------------------------------------------------------------

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Stylised "G" — Google brand colours rotated around the centre.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final strokeWidth = size.width * 0.14;

    const colors = [
      Color(0xFF4285F4), // blue
      Color(0xFF34A853), // green
      Color(0xFFFBBC05), // yellow
      Color(0xFFEA4335), // red
    ];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * 90 - 45) * 3.14159 / 180,
        90 * 3.14159 / 180,
        false,
        paint,
      );
    }

    // Inner "G" bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        radius + strokeWidth / 2,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AmazonSmilePainter extends CustomPainter {
  final Color color;
  _AmazonSmilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.45
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.4,
        size.width,
        size.height * 0.2,
      );
    canvas.drawPath(path, paint);

    // Arrow tip
    final tipPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final tipPath = Path()
      ..moveTo(size.width * 0.78, size.height * 0.3)
      ..lineTo(size.width * 1.05, size.height * 0.5)
      ..lineTo(size.width * 0.85, size.height * 0.7)
      ..close();
    canvas.drawPath(tipPath, tipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AirbnbBeloPainter extends CustomPainter {
  final Color color;
  _AirbnbBeloPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Stylised "Bélo" shape — heart/balloon-on-pin silhouette.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(w * 0.5, h * 0.04);
    // Left side curve
    path.cubicTo(w * 0.0, h * 0.32, w * 0.18, h * 0.78, w * 0.5, h * 0.96);
    // Right side curve back up
    path.cubicTo(w * 0.82, h * 0.78, w * 1.0, h * 0.32, w * 0.5, h * 0.04);
    path.close();

    canvas.drawPath(path, paint);

    // Inner cut-out to give "Bélo" its negative-space heart look.
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;
    final cut = Path();
    cut.addOval(Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.5),
      radius: w * 0.16,
    ));
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawPath(path, paint);
    canvas.drawPath(cut, cutPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
