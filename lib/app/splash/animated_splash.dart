import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/brand_logo.dart';
import '../../core/l10n/l10n.dart';

/// Colours of the splash, matched by the native launch screens
/// (android res/values/colors.xml and drawable/splash_logo.xml,
/// ios LaunchScreen.storyboard).
abstract final class SplashColors {
  static const top = AppColors.navy;
  static const bottom = AppColors.brand;
  static const accent = AppColors.mint;
}

/// Size of the logo box. The native Android 12+ splash draws the same
/// logo at this size in the middle of the screen, so the hand-over from
/// the native splash to Flutter does not move anything.
const splashLogoSize = 128.0;

/// The splash background: the native colour, with the gradient and two
/// glows faded in by [reveal] (0..1).
class SplashBackground extends StatelessWidget {
  const SplashBackground({this.reveal = 1, super.key});

  final double reveal;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: SplashColors.top,
    child: Opacity(
      opacity: reveal.clamp(0, 1),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SplashColors.top, SplashColors.bottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Glow(
              alignment: Alignment(-1.1 + 0.3 * reveal, -0.75),
              size: 320,
              color: SplashColors.bottom.withValues(alpha: 0.55),
            ),
            _Glow(
              alignment: Alignment(1.1 - 0.3 * reveal, 0.85),
              size: 380,
              color: SplashColors.accent.withValues(alpha: 0.16),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// Animated intro. Its first frame is the native launch screen (logo in
/// the centre on the brand colour), so it starts without a jump: the
/// minute hand sweeps a full turn, a light runs round the ring, the check
/// badge bounces, the logo gives one beat and the name rises in below.
/// Calls [onIntroDone] once. While the app is still loading after that,
/// the minute hand keeps turning as the loading indicator.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({
    this.onIntroDone,
    this.stillLoading = true,
    this.startedAt,
    this.skipIntro = false,
    super.key,
  });

  /// Start at the end state: the loading screen after sign-in looks like
  /// the splash without playing the intro again.
  final bool skipIntro;

  final VoidCallback? onIntroDone;
  final bool stillLoading;

  /// When the intro began. The splash is shown twice during start (once
  /// while the backend initialises, then inside the app); passing the same
  /// start lets the second one carry on where the first was, not restart.
  final DateTime? startedAt;

  static const duration = Duration(milliseconds: 1600);

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AnimatedSplash.duration,
  );

  Animation<double> _part(double from, double to, [Curve c = Curves.easeOut]) =>
      CurvedAnimation(
        parent: _c,
        curve: Interval(from, to, curve: c),
      );

  late final _reveal = _part(0, 0.5, Curves.easeOutCubic);
  late final _sweep = _part(0, 0.6, Curves.easeInOutCubic);
  late final _comet = _part(0.05, 0.65, Curves.easeInOut);
  late final _beat = _part(0.45, 0.75);
  late final _badge = _part(0.35, 0.7);
  late final _title = _part(0.45, 0.8, Curves.easeOutCubic);
  late final _subtitle = _part(0.6, 0.95, Curves.easeOutCubic);

  /// One turn of the minute hand per second while loading.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (widget.skipIntro) {
      _c.value = 1;
      _syncLoop();
    } else if (_reduceMotion) {
      // Reduced motion: jump to the end state.
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _done());
    } else {
      final started = widget.startedAt;
      final from = started == null
          ? 0.0
          : DateTime.now().difference(started).inMilliseconds /
                AnimatedSplash.duration.inMilliseconds;
      _c.forward(from: from.clamp(0.0, 1.0)).whenComplete(() {
        _done();
        _syncLoop();
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedSplash old) {
    super.didUpdateWidget(old);
    _syncLoop();
  }

  void _syncLoop() {
    if (!mounted) return;
    final spin = _c.isCompleted && widget.stillLoading && !_reduceMotion;
    if (spin && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!spin && _loop.isAnimating) {
      // Finish the current turn so the hand comes to rest at 2 o'clock.
      _loop.forward();
    }
  }

  void _done() {
    if (mounted) widget.onIntroDone?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// 1 → 1.08 → 1, one "heartbeat".
  static double _pulse(double t, double amount) =>
      1 + amount * math.sin(math.pi * t.clamp(0, 1));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion(
      value: systemBarsOnDark,
      child: Material(
        key: Key(widget.skipIntro ? 'loadingSplash' : 'splash'),
        color: SplashColors.top,
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _loop]),
          builder: (context, _) => LayoutBuilder(
            builder: (context, box) => Stack(
              fit: StackFit.expand,
              children: [
                SplashBackground(reveal: _reveal.value),
                Center(
                  child: Semantics(
                    label: widget.stillLoading ? context.l10n.loading : null,
                    child: Transform.scale(
                      scale: _pulse(_beat.value, 0.07),
                      child: SizedBox.square(
                        dimension: splashLogoSize,
                        child: BamsenetLogo(
                          sweep: _sweep.value + _loop.value,
                          comet: _comet.value,
                          badgeScale: _pulse(_badge.value, 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: box.maxHeight / 2 + splashLogoSize / 2 + Gap.xl,
                  child: Column(
                    children: [
                      _Rise(
                        t: _title.value,
                        child: Text(
                          'Zeiterfassung',
                          style: text.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: Gap.xs),
                      _Rise(
                        t: _subtitle.value,
                        child: Text(
                          'BAMSENET',
                          style: text.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rise extends StatelessWidget {
  const _Rise({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: t.clamp(0, 1),
    child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
  );
}
