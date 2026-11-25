import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../errors/app_failure.dart';

export '../../l10n/generated/app_localizations.dart';

/// App strings plus the Material, Cupertino and Widgets translations.
/// The generated AppLocalizations.localizationsDelegates still points at the
/// deprecated flutter_localizations delegates, which no longer match
/// material_ui's types, so this list is the one to use.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension FailureText on AppFailure {
  /// The user-facing German text for this failure.
  String message(AppLocalizations l) => switch (this) {
    NoConnection() => l.errorNoConnection,
    InvalidCredentials() => l.errorInvalidCredentials,
    AccountDisabled() => l.errorAccountDisabled,
    SessionExpired() => l.errorSessionExpired,
    AccessDenied() => l.errorAccessDenied,
    ServerFailure() => l.errorServer,
    UnknownFailure() => l.errorUnknown,
  };
}
