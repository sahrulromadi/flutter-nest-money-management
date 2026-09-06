import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Motif visual bertema Karasuno (Haikyuu!!) — gagak, bulu, garis lapangan voli.
/// Semua pakai CustomPainter / path, zero asset. Ilustrasi lebih kaya bisa
/// nyusul sbg SVG/PNG tanpa ngubah call site (ponytail: struktur ready).

/// Siluet gagak sederhana (monokrom, di-tint via [color]).
class CrowMark extends StatelessWidget {
  const CrowMark({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrowPainter(
        color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
      ),
    );
  }
}

class _CrowPainter extends CustomPainter {
  _CrowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width, h = size.height;

    // Badan + kepala (siluet gagak nangkring, menghadap kanan).
    final body = Path()
      ..moveTo(w * 0.20, h * 0.62)
      ..quadraticBezierTo(w * 0.30, h * 0.30, w * 0.55, h * 0.34)
      ..quadraticBezierTo(w * 0.66, h * 0.16, w * 0.74, h * 0.20)
      ..quadraticBezierTo(w * 0.70, h * 0.28, w * 0.72, h * 0.34)
      ..lineTo(w * 0.92, h * 0.30) // paruh
      ..lineTo(w * 0.74, h * 0.42)
      ..quadraticBezierTo(w * 0.80, h * 0.66, w * 0.60, h * 0.78)
      ..quadraticBezierTo(w * 0.40, h * 0.88, w * 0.20, h * 0.62)
      ..close();
    canvas.drawPath(body, p);

    // Sayap terangkat (spike energy).
    final wing = Path()
      ..moveTo(w * 0.40, h * 0.50)
      ..quadraticBezierTo(w * 0.30, h * 0.18, w * 0.10, h * 0.08)
      ..quadraticBezierTo(w * 0.28, h * 0.34, w * 0.34, h * 0.56)
      ..close();
    canvas.drawPath(wing, p);

    // Kaki.
    final legs = Paint()
      ..color = color
      ..strokeWidth = w * 0.03
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.42, h * 0.78), Offset(w * 0.42, h * 0.92), legs);
    canvas.drawLine(Offset(w * 0.52, h * 0.80), Offset(w * 0.52, h * 0.92), legs);
  }

  @override
  bool shouldRepaint(_CrowPainter old) => old.color != color;
}

/// Gagak yang meluncur nyebrang lebar parent-nya, loop terus, sambil ngepak
/// & naik-turun halus. Zero asset (CustomPainter). Buat header Home.
class FlyingCrow extends StatefulWidget {
  const FlyingCrow({
    super.key,
    this.color,
    this.size = 22,
    this.duration = const Duration(seconds: 9),
  });

  final Color? color;
  final double size;
  final Duration duration;

  @override
  State<FlyingCrow> createState() => _FlyingCrowState();
}

class _FlyingCrowState extends State<FlyingCrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ??
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value; // 0..1 posisi horizontal
            final x = -widget.size + t * (w + widget.size * 2);
            final bob = math.sin(t * math.pi * 6) * 3; // naik-turun
            final flap = (math.sin(t * math.pi * 18) * 0.5 + 0.5); // 0..1 kepak
            return Stack(
              children: [
                Positioned(
                  left: x,
                  top: (constraints.maxHeight - widget.size) / 2 + bob,
                  child: CustomPaint(
                    size: Size.square(widget.size),
                    painter: _FlyingCrowPainter(color, flap),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FlyingCrowPainter extends CustomPainter {
  _FlyingCrowPainter(this.color, this.flap);
  final Color color;
  final double flap; // 0 = sayap turun, 1 = sayap naik

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width, h = size.height;
    // sudut sayap: -0.35 (turun) .. 0.35 (naik)
    final a = (flap - 0.5) * 0.7;

    final path = Path()
      ..moveTo(w * 0.5, h * 0.55) // badan tengah
      // sayap kiri
      ..quadraticBezierTo(
          w * 0.25, h * (0.55 - a), w * 0.02, h * (0.5 - a * 1.6))
      ..quadraticBezierTo(w * 0.28, h * 0.6, w * 0.5, h * 0.62)
      // sayap kanan
      ..quadraticBezierTo(
          w * 0.75, h * (0.55 - a), w * 0.98, h * (0.5 - a * 1.6))
      ..quadraticBezierTo(w * 0.72, h * 0.6, w * 0.5, h * 0.55)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_FlyingCrowPainter old) =>
      old.flap != flap || old.color != color;
}

/// Motif bulu/sayap samar — buat background header.
class FeatherBackdrop extends StatelessWidget {
  const FeatherBackdrop({super.key, this.color, this.opacity = 0.08});

  final Color? color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FeatherPainter(
        (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: opacity),
      ),
    );
  }
}

class _FeatherPainter extends CustomPainter {
  _FeatherPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;

    // Barisan garis diagonal makin pendek — kesan bulu / kepakan sayap.
    for (var i = 0; i < 7; i++) {
      final x = w * (0.55 + i * 0.07);
      final len = h * (0.55 - i * 0.06);
      canvas.drawLine(
        Offset(x, h * 0.15),
        Offset(x - len * 0.5, h * 0.15 + len),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_FeatherPainter old) => old.color != color;
}

/// Divider gaya garis lapangan voli — dua garis tipis sejajar.
class CourtDivider extends StatelessWidget {
  const CourtDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.outline.withValues(alpha: 0.6);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1.5, color: c),
          const SizedBox(height: 3),
          Container(height: 1, color: c.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
