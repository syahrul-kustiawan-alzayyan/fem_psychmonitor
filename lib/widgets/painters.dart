import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ring progress melingkar dengan animasi — dipakai untuk confidence
/// emosi (live & hasil) agar terasa "instrumen", bukan sekadar angka.
class ConfidenceRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  const ConfidenceRing({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.size = 88,
    this.strokeWidth = 5,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                value: value,
                color: color,
                trackColor: trackColor,
                strokeWidth: strokeWidth,
              ),
            ),
            if (child != null) Center(child: child),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = strokeWidth;
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(inner, 0, math.pi * 2, false, track);

    if (value > 0.005) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(inner, -math.pi / 2, math.pi * 2 * value, false, arc);

      // Titik ujung kecil — kesan presisi instrumen.
      final angle = -math.pi / 2 + math.pi * 2 * value;
      final center = inner.center;
      final radius = inner.shortestSide / 2;
      final knobPos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final knob = Paint()..color = color;
      canvas.drawCircle(knobPos, stroke * 0.85, knob);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// Garis putus-putus horizontal — gaya "struk/nota" untuk baris kalkulasi.
class DashedLine extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashGap;

  const DashedLine({
    super.key,
    required this.color,
    this.height = 1,
    this.dashWidth = 4,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _DashedPainter(
        color: color,
        dashWidth: dashWidth,
        dashGap: dashGap,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;

  _DashedPainter({
    required this.color,
    required this.dashWidth,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(math.min(x + dashWidth, size.width), size.height / 2),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.color != color;
}
