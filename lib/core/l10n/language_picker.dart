import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../design/motion.dart';
import 'l10n.dart';
import 'language.dart';

/// Language names are shown in their own language, so a user who cannot
/// read the current one still finds theirs.
String languageName(AppLanguage language, AppLocalizations l) =>
    switch (language) {
      AppLanguage.system => l.languageSystem,
      AppLanguage.de => 'Deutsch',
      AppLanguage.en => 'English',
    };

Future<void> showLanguagePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(languageProvider);
  final picked = await showDialog<AppLanguage>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(ctx.l10n.language),
      children: [
        for (final a in AppLanguage.values)
          Semantics(
            selected: a == current,
            child: SimpleDialogOption(
              key: Key('language-${a.name}'),
              onPressed: () => Navigator.pop(ctx, a),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(child: Text(languageName(a, ctx.l10n))),
                    if (a == current) const Icon(Icons.check),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
  if (picked != null && picked != current) {
    await ref.read(languageProvider.notifier).choose(picked);
  }
}

/// Compact button for screens without the More menu (sign-in).
class LanguageButton extends ConsumerWidget {
  const LanguageButton({this.onDark = false, super.key});

  /// White text, for navy headers.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    key: const Key('languageButton'),
    style: onDark ? TextButton.styleFrom(foregroundColor: Colors.white) : null,
    onPressed: () {
      Haptics.selection();
      showLanguagePicker(context, ref);
    },
    icon: const Icon(Icons.language),
    label: Text(languageName(ref.watch(languageProvider), context.l10n)),
  );
}
