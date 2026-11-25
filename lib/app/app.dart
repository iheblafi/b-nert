import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import '../core/l10n/l10n.dart';
import '../core/l10n/language.dart';
import '../core/network/network_status.dart';
import '../features/app_lock/app_lock.dart';
import '../features/auth/state/session.dart';
import 'app_overlays.dart';
import 'router.dart';

class BamsenetApp extends ConsumerStatefulWidget {
  const BamsenetApp({this.splashStartedAt, super.key});

  /// Start of the intro shown by main() before the app was ready.
  final DateTime? splashStartedAt;

  @override
  ConsumerState<BamsenetApp> createState() => _BamsenetAppState();
}

class _BamsenetAppState extends ConsumerState<BamsenetApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Settings and permissions are refreshed on return to the foreground.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(appLockProvider.notifier).resumed();
        ref.read(sessionProvider.notifier).refreshContext();
      },
      onPause: () => ref.read(appLockProvider.notifier).paused(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Back online: load again what failed or may be stale.
    ref.listen(onlineProvider, (prev, next) {
      if (prev?.value == false && next.value == true) {
        ref.read(sessionProvider.notifier).refreshContext();
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: ref.watch(languageProvider).locale,
      localeListResolutionCallback: (preferred, _) => resolveLocale(preferred),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => AppOverlays(
        splashStartedAt: widget.splashStartedAt,
        child: child ?? const SizedBox(),
      ),
    );
  }
}
