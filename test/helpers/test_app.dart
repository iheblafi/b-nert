import 'dart:async';

import 'package:flutter_mobile/app/app.dart';
import 'package:flutter_mobile/core/l10n/language.dart';
import 'package:flutter_mobile/core/network/network_status.dart';
import 'package:flutter_mobile/core/security/biometrics.dart';
import 'package:flutter_mobile/core/session/secret_store.dart';
import 'package:flutter_mobile/features/app_lock/app_lock.dart';
import 'package:flutter_mobile/features/auth/state/session.dart';
import 'package:flutter_mobile/features/time_entry/data/entry_options_repository.dart';
import 'package:flutter_mobile/features/times/state/overview_provider.dart';
import 'package:flutter_mobile/features/user_context/data/user_context_cache.dart';
import 'package:flutter_mobile/features/user_context/data/user_context_repository.dart';
import 'package:flutter_mobile/features/user_context/model/user_context.dart';
import 'package:flutter_mobile/features/user_context/state/user_context_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_auth_repository.dart';
import 'fake_overview_repository.dart';
import 'fixtures.dart';
import 'memory_secret_store.dart';

class FakeContextRepository implements UserContextRepository {
  FakeContextRepository([UserContext? ctx]) : result = ctx ?? userContext();
  Object result;
  int loads = 0;

  @override
  Future<UserContext> load(String userId) async {
    loads++;
    final r = result;
    if (r is UserContext) return r;
    throw r;
  }
}

/// Network that tests switch on and off with [online].
class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus([this._online = true]);

  bool _online;
  final _changes = StreamController<bool>.broadcast();

  set online(bool value) {
    _online = value;
    _changes.add(value);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get changes => _changes.stream;
}

/// Fingerprint prompt that answers [result]; [prompts] counts the asks.
class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.available = true, this.result = true});

  bool available;
  bool result;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return result;
  }
}

/// A typical phone (360 x 780 logical pixels) instead of the 800 x 600
/// test default, so layouts are checked at the size people use.
void usePhoneScreen(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2340)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The keystore in tests; fresh for every pumped app.
MemorySecretStore testSecrets = MemorySecretStore();

/// The backend overview and form options of the last pumped app.
FakeOverviewRepository testOverview = FakeOverviewRepository();
FakeEntryOptionsRepository testEntryOptions = FakeEntryOptionsRepository();

/// The app's clock in tests; move it forward by hand.
DateTime testNow = DateTime(2026, 11, 24, 9);

List<Override> testOverrides(
  FakeAuthRepository auth,
  FakeContextRepository contexts, [
  FakeNetworkStatus? network,
  FakeBiometrics? biometrics,
]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  return [
    authRepositoryProvider.overrideWithValue(auth),
    secretStoreProvider.overrideWithValue(testSecrets = MemorySecretStore()),
    clockProvider.overrideWithValue(() => testNow),
    networkStatusProvider.overrideWithValue(network ?? FakeNetworkStatus()),
    // No fingerprint unless a test sets one up: keeps the offer dialog out
    // of the other flows.
    biometricsProvider.overrideWithValue(
      biometrics ?? FakeBiometrics(available: false),
    ),
    userContextRepositoryProvider.overrideWithValue(contexts),
    overviewRepositoryProvider.overrideWithValue(
      testOverview = FakeOverviewRepository(),
    ),
    entryOptionsRepositoryProvider.overrideWithValue(
      testEntryOptions = FakeEntryOptionsRepository(),
    ),
    userContextCacheProvider.overrideWithValue(
      UserContextCache(SharedPreferencesAsync()),
    ),
  ];
}

/// [device] is the phone's language list; [saved] a choice stored earlier.
Future<void> pumpFullApp(
  WidgetTester tester,
  FakeAuthRepository auth, [
  FakeContextRepository? contexts,
  List<Locale> device = const [Locale('de', 'DE')],
  AppLanguage saved = AppLanguage.system,
  FakeNetworkStatus? network,
  FakeBiometrics? biometrics,
  bool lockEnabled = false,
]) async {
  usePhoneScreen(tester);
  tester.platformDispatcher.localesTestValue = device;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(
          auth,
          contexts ?? FakeContextRepository(),
          network,
          biometrics,
        ),
        initialLanguageProvider.overrideWithValue(saved),
        initialAppLockProvider.overrideWithValue(lockEnabled),
      ],
      child: const BamsenetApp(),
    ),
  );
  await tester.pumpAndSettle();
}
