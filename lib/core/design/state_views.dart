import 'package:material_ui/material_ui.dart';

import '../errors/app_failure.dart';
import '../l10n/l10n.dart';
import 'app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Error state with retry; every screen uses it (spec section 9).
class ErrorView extends StatelessWidget {
  const ErrorView({required this.failure, this.onRetry, super.key});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failure is NoConnection ? Icons.cloud_off : Icons.error_outline,
              size: 48,
              semanticLabel: '',
            ),
            const SizedBox(height: Gap.m),
            Text(failure.message(l), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: Gap.m),
              OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
