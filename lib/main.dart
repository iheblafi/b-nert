import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/splash/animated_splash.dart';
import 'core/backend/backend.dart';
import 'core/config/app_config.dart';
import 'core/design/app_theme.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/language.dart';
import 'core/session/secret_store.dart';
import 'features/app_lock/app_lock.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/state/session.dart';
import 'features/user_context/data/user_context_cache.dart';
import 'features/user_context/data/user_context_repository.dart';
import 'features/user_context/state/user_context_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw the animated intro on the first frame; everything below loads
  // behind it instead of holding the native launch screen.
  final splashStartedAt = DateTime.now();
  runApp(_BootSplash(startedAt: splashStartedAt));
  final config = AppConfig.fromEnvironment();
  if (!config.hasBackend) {
    runApp(const _MissingConfigApp());
    return;
  }
  final client = await initBackend(config);
  final languages = LanguageStore(SharedPreferencesAsync());
  final language = await languages.read();
  final locks = AppLockStore(SharedPreferencesAsync());
  final lockEnabled = await locks.enabled();
  final hasSavedSignIn =
      await SavedSignIn(KeystoreSecretStore()).read() != null;
  runApp(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(client.auth),
        ),
        userContextRepositoryProvider.overrideWithValue(
          SupabaseUserContextRepository(client),
        ),
        languageStoreProvider.overrideWithValue(languages),
        initialLanguageProvider.overrideWithValue(language),
        appLockStoreProvider.overrideWithValue(locks),
        initialAppLockProvider.overrideWithValue(lockEnabled),
        initialSavedSignInProvider.overrideWithValue(hasSavedSignIn),
        userContextCacheProvider.overrideWithValue(
          UserContextCache(SharedPreferencesAsync()),
        ),
      ],
      child: BamsenetApp(splashStartedAt: splashStartedAt),
    ),
  );
}

/// The intro while main() initialises the backend. The app takes over
/// with the same start time, so the animation continues seamlessly.
class _BootSplash extends StatelessWidget {
  const _BootSplash({required this.startedAt});

  final DateTime startedAt;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeListResolutionCallback: (preferred, _) => resolveLocale(preferred),
    home: AnimatedSplash(startedAt: startedAt),
  );
}

/// Shown by builds made without --dart-define-from-file (see README).
class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Backend nicht konfiguriert.\n'
            'flutter run --dart-define-from-file=config/stage.json',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
