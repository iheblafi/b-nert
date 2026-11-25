import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/design/motion.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../state/session.dart';
import 'validators.dart';

/// Spec F1, AC7 and AC8: the answer is the same whether or not the account
/// exists; the link in the mail opens the web page.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  AppFailure? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
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
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(_email.text);
      Haptics.success();
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (f) {
      Haptics.error();
      if (mounted) setState(() => _error = f);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go('/sign-in');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ResetHeader(title: l.resetTitle, onBack: _back),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.m + 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SoftCard(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: SizeTransition(
                          sizeFactor: a,
                          alignment: Alignment.topCenter,
                          child: child,
                        ),
                      ),
                      child: _sent
                          ? Column(
                              key: const ValueKey('sent'),
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.mint.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.mark_email_read_rounded,
                                    size: 42,
                                    color: theme.brightness == Brightness.dark
                                        ? AppColors.mint
                                        : AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: Gap.l),
                                Text(
                                  l.resetSentTitle,
                                  style: theme.textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: Gap.s),
                                Text(
                                  l.resetSent,
                                  key: const Key('resetSent'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: Gap.l),
                                PressScale(
                                  child: FilledButton(
                                    onPressed: () => context.go('/sign-in'),
                                    child: Text(l.backToSignIn),
                                  ),
                                ),
                              ],
                            )
                          : Form(
                              key: _form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    l.resetIntro,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: Gap.l),
                                  TextFormField(
                                    controller: _email,
                                    decoration: InputDecoration(
                                      labelText: l.email,
                                      prefixIcon: const Icon(
                                        Icons.mail_outline,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    autocorrect: false,
                                    textInputAction: TextInputAction.send,
                                    onFieldSubmitted: (_) => _send(),
                                    validator: (v) => validateEmail(v, l),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: Gap.m),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 20,
                                          color: scheme.error,
                                        ),
                                        const SizedBox(width: Gap.s),
                                        Expanded(
                                          child: Text(
                                            _error!.message(l),
                                            style: TextStyle(
                                              color: scheme.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: Gap.l),
                                  PressScale(
                                    child: FilledButton.icon(
                                      onPressed: _busy ? null : _send,
                                      icon: _busy
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded),
                                      label: Text(l.resetSend),
                                    ),
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

/// Navy header with a back button, the reset icon and the title.
class _ResetHeader extends StatelessWidget {
  const _ResetHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
            padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xs, Gap.m, 64),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('back'),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: onBack,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: Gap.m),
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
