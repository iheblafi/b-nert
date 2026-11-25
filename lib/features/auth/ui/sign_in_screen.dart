import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/splash/animated_splash.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/design/brand_logo.dart';
import '../../../core/design/motion.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/language_picker.dart';
import '../../app_lock/app_lock.dart';
import '../state/session.dart';
import 'validators.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  AppFailure? _error;
  String? _notice;

  /// The logo's flight from the splash centre into the header.
  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void initState() {
    super.initState();
    if (ref.read(splashDoneProvider)) {
      // Coming back after sign-out: a short settle, no flight.
      _flight.value = 0.55;
      _flight.forward();
    }
  }

  @override
  void dispose() {
    _flight.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_form.currentState?.validate() ?? false)) {
      Haptics.error();
      return;
    }
    Haptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    // Set before signing in: the home screen may appear before signIn
    // returns, and it asks about biometric unlock once.
    ref
        .read(appLockProvider.notifier)
        .signedInWithPassword(_email.text, _password.text);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      // The session listener moves on to the home screen.
      ref.read(celebrationProvider.notifier).celebrate();
    } on AppFailure catch (f) {
      Haptics.error();
      ref.read(appLockProvider.notifier).signInFailed();
      if (mounted) setState(() => _error = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _quickSignIn() async {
    if (_busy) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await ref
          .read(appLockProvider.notifier)
          .quickSignIn(l.lockReason);
      switch (result) {
        case QuickSignInResult.signedIn:
          ref.read(celebrationProvider.notifier).celebrate();
        case QuickSignInResult.passwordChanged:
          Haptics.error();
          if (mounted) setState(() => _notice = l.savedSignInInvalid);
        case QuickSignInResult.cancelled:
          break;
      }
    } on AppFailure catch (f) {
      Haptics.error();
      if (mounted) setState(() => _error = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(splashDoneProvider, (_, done) {
      if (done) _flight.forward();
    });
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quick = ref.watch(appLockProvider).canQuickSignIn;
    final session = ref.watch(sessionProvider);
    final shown = _error ?? (session is SignedOut ? session.reason : null);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(flight: _flight),
            Transform.translate(
              offset: const Offset(0, -44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.m + 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SoftCard(
                    child: AutofillGroup(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.welcomeBack,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: Gap.xs),
                            Text(
                              l.signInHint,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: Gap.l),
                            TextFormField(
                              key: const Key('email'),
                              controller: _email,
                              decoration: InputDecoration(
                                labelText: l.email,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              validator: (v) => validateEmail(v, l),
                            ),
                            const SizedBox(height: Gap.m),
                            TextFormField(
                              key: const Key('password'),
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: l.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? l.showPassword
                                      : l.hidePassword,
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    Haptics.selection();
                                    setState(() => _obscure = !_obscure);
                                  },
                                ),
                              ),
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) =>
                                  (v ?? '').isEmpty ? l.passwordRequired : null,
                            ),
                            if (shown != null) ...[
                              const SizedBox(height: Gap.m),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 20,
                                    color: scheme.error,
                                  ),
                                  const SizedBox(width: Gap.s),
                                  Expanded(
                                    child: Text(
                                      shown.message(l),
                                      key: const Key('signInError'),
                                      style: TextStyle(color: scheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: Gap.l),
                            PressScale(
                              child: FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l.signIn),
                              ),
                            ),
                            if (quick) ...[
                              const SizedBox(height: Gap.m),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Gap.s,
                                    ),
                                    child: Text(
                                      l.or,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: Gap.m),
                              PressScale(
                                child: OutlinedButton.icon(
                                  key: const Key('quickSignIn'),
                                  // Secondary action: smaller than Anmelden.
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    textStyle: theme.textTheme.labelLarge
                                        ?.copyWith(fontSize: 14),
                                    iconSize: 20,
                                  ),
                                  onPressed: _busy ? null : _quickSignIn,
                                  icon: const Icon(Icons.fingerprint),
                                  label: Text(l.quickSignIn),
                                ),
                              ),
                            ],
                            if (_notice != null) ...[
                              const SizedBox(height: Gap.m),
                              Text(
                                _notice!,
                                key: const Key('signInNotice'),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: Gap.s),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(l.forgotPassword),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navy header with the logo. The logo starts where the splash logo was
/// (screen centre, splash size) and flies up into place.
class _Header extends StatelessWidget {
  const _Header({required this.flight});

  final Animation<double> flight;

  static const logoSize = 76.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final text = Theme.of(context).textTheme;
    // Where the logo ends: under the status bar and the language button.
    final restCentreY = media.padding.top + 56 + logoSize / 2;
    final startDy = media.size.height / 2 - restCentreY;
    const startScale = splashLogoSize / logoSize;
    return AnnotatedRegion(
      value: systemBarsOnDark,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.brand],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(Radii.sheet + 8),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.s, 0, Gap.s, 72),
            child: AnimatedBuilder(
              animation: flight,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(flight.value);
                final textIn = Curves.easeOut.transform(
                  ((flight.value - 0.5) / 0.5).clamp(0.0, 1.0),
                );
                return Column(
                  children: [
                    const SizedBox(
                      height: 48,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: LanguageButton(onDark: true),
                      ),
                    ),
                    const SizedBox(height: Gap.s),
                    Transform.translate(
                      offset: Offset(0, startDy * (1 - t)),
                      child: Transform.scale(
                        scale: startScale + (1 - startScale) * t,
                        child: const SizedBox.square(
                          dimension: logoSize,
                          child: BamsenetLogo(),
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    Opacity(
                      opacity: textIn,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - textIn)),
                        child: Column(
                          children: [
                            Text(
                              'Zeiterfassung',
                              style: text.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'BAMSENET',
                              style: text.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
