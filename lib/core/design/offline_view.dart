import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import 'app_theme.dart';

/// The "no connection" content: illustration, title, explanation, retry.
/// Used full screen by [OfflineScreen] and inside the context-failed gate.
class OfflineView extends StatelessWidget {
  const OfflineView({this.onRetry, super.key});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      key: const Key('offlineScreen'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.l),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          // One-shot entrance: the screen eases in instead of popping up.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - t)),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 76,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: Gap.xl),
                Text(
                  l.offlineTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Gap.m),
                Text(
                  l.offlineBody,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: Gap.xl),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(l.retry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full screen shown above the whole app while the phone is offline.
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({this.onRetry, super.key});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: systemBarsFor(Theme.of(context)),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(child: OfflineView(onRetry: onRetry)),
    ),
  );
}
