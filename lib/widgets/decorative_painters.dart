import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DecorativePainters — Ilustrasi dekoratif untuk kartu statistik
// Ganti ikon Phosphor dengan grafis kustom yang lebih lembut & organik
// ─────────────────────────────────────────────────────────────────────────────

/// Bunga kecil — merekam / recordings
class FlowerPainter extends CustomPainter {
  final Color color;
  FlowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.18;

    // Petal
    final petalPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.55);

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final px = cx + math.cos(angle) * r * 1.1;
      final py = cy + math.sin(angle) * r * 1.1;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: r * 1.3, height: r * 0.7),
        petalPaint,
      );
    }

    // Pusat
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(Offset(cx, cy), r * 0.55, centerPaint);

    // Daun kecil di bawah
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.35);
    final leafPath = Path()
      ..moveTo(cx, cy + r * 1.5)
      ..quadraticBezierTo(cx - r * 1.2, cy + r * 1.8, cx - r * 0.4, cy + r * 2.5)
      ..quadraticBezierTo(cx, cy + r * 2.1, cx + r * 0.4, cy + r * 2.5)
      ..quadraticBezierTo(cx + r * 1.2, cy + r * 1.8, cx, cy + r * 1.5)
      ..close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant FlowerPainter old) => old.color != color;
}

/// Matahari / smiley — positif
class SunSmilePainter extends CustomPainter {
  final Color color;
  SunSmilePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.22;

    // Sinar matahari
    final rayPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.4);

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final inner = r * 1.35;
      final outer = r * 1.85;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * inner, cy + math.sin(angle) * inner),
        Offset(cx + math.cos(angle) * outer, cy + math.sin(angle) * outer),
        rayPaint,
      );
    }

    // Lingkaran utama
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final mainPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(Offset(cx, cy), r * 0.82, mainPaint);

    // Mata
    final eyePaint = Paint()..color = Colors.white;
    final eyeR = r * 0.13;
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.15), eyeR, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.15), eyeR, eyePaint);

    // Senyum
    final smilePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final smileRect = Rect.fromCenter(
      center: Offset(cx, cy + r * 0.15),
      width: r * 0.8,
      height: r * 0.5,
    );
    canvas.drawArc(smileRect, 0.1, math.pi - 0.2, false, smilePaint);
  }

  @override
  bool shouldRepaint(covariant SunSmilePainter old) => old.color != color;
}

/// Hati dengan daun — perlu perhatian
class HeartLeafPainter extends CustomPainter {
  final Color color;
  HeartLeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.24;

    // Hati
    final heartPath = Path();
    heartPath.moveTo(cx, cy + s * 0.7);
    heartPath.cubicTo(cx - s * 1.6, cy - s * 0.2, cx - s * 0.8, cy - s * 1.3, cx, cy - s * 0.6);
    heartPath.cubicTo(cx + s * 0.8, cy - s * 1.3, cx + s * 1.6, cy - s * 0.2, cx, cy + s * 0.7);
    heartPath.close();

    final heartBg = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.22);
    canvas.drawPath(heartPath, heartBg);

    final heartMain = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(heartPath, heartMain);

    // Daun kecil di atas
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.45);
    final leaf1 = Path()
      ..moveTo(cx + s * 0.3, cy - s * 1.1)
      ..quadraticBezierTo(cx + s * 1.0, cy - s * 1.8, cx + s * 0.6, cy - s * 2.2)
      ..quadraticBezierTo(cx + s * 0.3, cy - s * 1.6, cx + s * 0.3, cy - s * 1.1)
      ..close();
    canvas.drawPath(leaf1, leafPaint);

    final leaf2 = Path()
      ..moveTo(cx - s * 0.3, cy - s * 1.1)
      ..quadraticBezierTo(cx - s * 1.0, cy - s * 1.8, cx - s * 0.6, cy - s * 2.2)
      ..quadraticBezierTo(cx - s * 0.3, cy - s * 1.6, cx - s * 0.3, cy - s * 1.1)
      ..close();
    canvas.drawPath(leaf2, leafPaint);
  }

  @override
  bool shouldRepaint(covariant HeartLeafPainter old) => old.color != color;
}

/// Timer / daun melingkar — sisa deteksi
class LeafTimerPainter extends CustomPainter {
  final Color color;
  LeafTimerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.2;

    // Daun melingkar sebagai "frame"
    final leafPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.5);

    // Upper-right leaf arc
    final leafArc = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.4, height: r * 2.4),
        -math.pi * 0.7,
        math.pi * 1.1,
      );
    canvas.drawPath(leafArc, leafPaint);

    // Lower-left leaf
    final leafPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35);

    final leafArc2 = Path()
      ..addArc(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2.0, height: r * 2.0),
        math.pi * 0.3,
        math.pi * 0.9,
      );
    canvas.drawPath(leafArc2, leafPaint2);

    // Lingkaran pusat
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(Offset(cx, cy), r * 0.75, bgPaint);

    final mainPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, mainPaint);

    // Jarum jam pendek
    final handPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx, cy - r * 0.4),
      handPaint,
    );
    // Jarum jam panjang
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.32, cy + r * 0.05),
      handPaint,
    );
    // Titik pusat
    canvas.drawCircle(Offset(cx, cy), 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant LeafTimerPainter old) => old.color != color;
}

/// Gelombang dekoratif — untuk card background
class WaveDecorationPainter extends CustomPainter {
  final Color color;
  final double animation;
  WaveDecorationPainter({required this.color, this.animation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.12);

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.7 +
          math.sin((x / size.width * 2 * math.pi) + animation) * size.height * 0.08;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.82);
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.82 +
          math.sin((x / size.width * 2 * math.pi) + animation + 1) * size.height * 0.06;
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.08));
  }

  @override
  bool shouldRepaint(covariant WaveDecorationPainter old) =>
      old.animation != animation || old.color != color;
}

/// Titik-titik kecil dekoratif散らし
class DotsDecorationPainter extends CustomPainter {
  final Color color;
  DotsDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);

    for (int i = 0; i < 12; i++) {
      final x = size.width * 0.6 + rng.nextDouble() * size.width * 0.35;
      final y = rng.nextDouble() * size.height;
      final r = 1.5 + rng.nextDouble() * 2.5;
      paint.color = color.withValues(alpha: 0.08 + rng.nextDouble() * 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotsDecorationPainter old) => old.color != color;
}
