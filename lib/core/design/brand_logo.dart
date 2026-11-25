import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

/// The clock-with-check logo. Painted on a 128 box and scaled, so it is
/// crisp at any size. With the defaults it is exactly the native launch
/// logo (android/app/src/main/res/drawable/splash_logo.xml).
class BamsenetLogo extends StatelessWidget {
  const BamsenetLogo({
    this.sweep = 0,
    this.comet = 0,
    this.badgeScale = 1,
    super.key,
  });

  /// 0..1: extra full turn of the minute hand.
  final double sweep;

  /// 0..1: a light running once round the ring; invisible at 0 and 1.
  final double comet;
  final double badgeScale;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ClockPainter(sweep: sweep, comet: comet, badgeScale: badgeScale),
  );
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({
    required this.sweep,
    required this.comet,
    required this.badgeScale,
  });

  /// 0..1: extra full turn of the minute hand.
  final double sweep;

  /// 0..1: a light running once round the ring; invisible at 0 and 1.
  final double comet;
  final double badgeScale;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry is defined on a 128 box.
    canvas.scale(size.shortestSide / 128);
    const c = Offset(64, 64);
    const r = 58.0;
    const top = -math.pi / 2;
    final ringRect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );

    if (comet > 0 && comet < 1) {
      const tail = math.pi * 0.6;
      final head = top + 2 * math.pi * comet;
      canvas.drawArc(
        ringRect,
        head - tail,
        tail,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: tail,
            colors: [AppColors.mint.withValues(alpha: 0), AppColors.mint],
            transform: GradientRotation(head - tail),
          ).createShader(ringRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }

    final tick = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i += 3) {
      final a = top + i * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * (r - 16), c + dir * (r - 9), tick);
    }

    Offset tip(double a, double len) =>
        c + Offset(math.cos(a), math.sin(a)) * len;
    final hand = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    // Rest position: hour hand at 9, minute hand at 2.
    const hour = math.pi;
    final minute = -math.pi / 6 + 2 * math.pi * sweep;
    canvas
      ..drawLine(c, tip(hour, r * 0.38), hand..strokeWidth = 6)
      ..drawLine(c, tip(minute, r * 0.62), hand..strokeWidth = 4.5)
      ..drawCircle(c, 6, Paint()..color = AppColors.mint);

    final b = c + const Offset(r * 0.72, r * 0.72);
    canvas
      ..save()
      ..translate(b.dx, b.dy)
      ..scale(badgeScale)
      ..drawCircle(Offset.zero, 20, Paint()..color = AppColors.mint)
      ..drawPath(
        Path()
          ..moveTo(-8, 0)
          ..lineTo(-2.5, 6)
          ..lineTo(9, -6),
        Paint()
          ..color = AppColors.navy
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.sweep != sweep || old.comet != comet || old.badgeScale != badgeScale;
}
