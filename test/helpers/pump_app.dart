import 'package:flutter_mobile/core/design/app_theme.dart';
import 'package:flutter_mobile/core/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_app.dart';

/// Pumps [child] with theme, German localisation and optional overrides.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
    ThemeData? theme,
  }) {
    usePhoneScreen(this);
    return pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: theme ?? AppTheme.light(),
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
  }
}
