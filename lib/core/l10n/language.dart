import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's language choice. [system] follows the device.
enum AppLanguage {
  system(null),
  de(Locale('de')),
  en(Locale('en'));

  const AppLanguage(this.locale);

  /// The forced locale, or null to follow the device.
  final Locale? locale;
}

/// German is the fallback for devices set to any other language.
const fallbackLocale = Locale('de');

/// Picks the app locale from the device's preferred languages.
Locale resolveLocale(List<Locale>? preferred) {
  for (final l in preferred ?? const <Locale>[]) {
    for (final a in AppLanguage.values) {
      if (a.locale?.languageCode == l.languageCode) return a.locale!;
    }
  }
  return fallbackLocale;
}

/// Keeps the choice on the device. It is a device setting, so sign-out
/// does not clear it.
class LanguageStore {
  LanguageStore(this._prefs);

  static const key = 'bamsenet.language';
  final SharedPreferencesAsync _prefs;

  Future<AppLanguage> read() async {
    final raw = await _prefs.getString(key);
    return AppLanguage.values.firstWhere(
      (a) => a.name == raw,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> write(AppLanguage language) =>
      _prefs.setString(key, language.name);
}

final languageStoreProvider = Provider<LanguageStore>(
  (_) => LanguageStore(SharedPreferencesAsync()),
);

/// The stored choice, read in main() before the first frame so the app
/// does not start in one language and switch to another.
final initialLanguageProvider = Provider<AppLanguage>(
  (_) => AppLanguage.system,
);

class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.read(initialLanguageProvider);

  Future<void> choose(AppLanguage language) async {
    state = language;
    await ref.read(languageStoreProvider).write(language);
  }
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);
