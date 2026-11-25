import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

/// Haptic feedback, one vocabulary for the whole app.
abstract final class Haptics {
  /// Tab changes, pickers, switches.
  static void selection() => HapticFeedback.selectionClick();

  /// Primary buttons.
  static void tap() => HapticFeedback.lightImpact();

  /// Signed in, unlocked.
  static void success() => HapticFeedback.mediumImpact();

  /// Wrong password, failed unlock.
  static void error() => HapticFeedback.heavyImpact();
}

/// Presses in slightly while touched, like a physical button.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, super.key});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// True once the start splash begins to leave. The sign-in page waits for
/// it, so its logo can fly up from where the splash logo was.
class SplashDoneController extends Notifier<bool> {
  @override
  bool build() => false;

  void done() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashDoneController, bool>(
  SplashDoneController.new,
);

/// Counts moments worth a checkmark (signed in, unlocked); the overlay
/// plays once per increase.
class CelebrationController extends Notifier<int> {
  @override
  int build() => 0;

  void celebrate() {
    Haptics.success();
    state++;
  }
}

final celebrationProvider = NotifierProvider<CelebrationController, int>(
  CelebrationController.new,
);

/// A mint circle pops in, the check draws itself, then everything fades.
class SuccessBurst extends StatelessWidget {
  const SuccessBurst({required this.t, super.key});

  /// 0..1 through the whole animation.
  final double t;

  static const duration = Duration(milliseconds: 950);

  @override
  Widget build(BuildContext context) {
    double part(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    final pop = Curves.elasticOut.transform(part(0, 0.55));
    final draw = Curves.easeOutCubic.transform(part(0.25, 0.6));
    final fade = 1 - Curves.easeIn.transform(part(0.7, 1));
    return IgnorePointer(
      child: Opacity(
        opacity: fade,
        child: Center(
          child: Transform.scale(
            scale: 0.4 + 0.6 * pop,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.45),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: CustomPaint(painter: _CheckPainter(draw)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final s = size.shortestSide;
    final path = Path()
      ..moveTo(s * 0.28, s * 0.52)
      ..lineTo(s * 0.44, s * 0.67)
      ..lineTo(s * 0.73, s * 0.36);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * math.min(progress, 1)),
      Paint()
        ..color = AppColors.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// Raised white (dark: navy) card with the soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(Gap.l),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(Radii.card);
    // Shadow outside, Material inside: list rows keep their tap ripple.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: softShadow(theme.brightness),
      ),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
