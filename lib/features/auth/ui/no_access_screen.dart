import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/l10n/l10n.dart';
import '../state/session.dart';

class NoAccessScreen extends ConsumerWidget {
  const NoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: Gap.m),
                Text(
                  l.noAccessTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: Gap.s),
                Text(l.noAccessBody, textAlign: TextAlign.center),
                const SizedBox(height: Gap.l),
                FilledButton(
                  onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                  child: Text(l.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
