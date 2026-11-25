import 'package:flutter_mobile/app/app.dart';
import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/core/l10n/language.dart';
import 'package:flutter_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

void main() {
  FakeAuthRepository signedIn() => FakeAuthRepository(
    user: const AuthUser(id: 'u1', email: 'a@b.de'),
  );

  Future<void> pump(
    WidgetTester tester,
    FakeAuthRepository auth,
    FakeContextRepository contexts,
    FakeNetworkStatus network,
  ) => pumpFullApp(
    tester,
    auth,
    contexts,
    const [Locale('de', 'DE')],
    AppLanguage.system,
    network,
  );

  final offlineScreen = find.byKey(const Key('offlineScreen'));

  testWidgets('animated splash plays at start, then gives way to the app', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(signedIn(), FakeContextRepository()),
        child: const BamsenetApp(),
      ),
    );
    expect(find.byKey(const Key('splash')), findsOneWidget);

    // Midway through the intro the name has appeared.
    await tester.pump(const Duration(milliseconds: 1200));
    // The loading route behind it shows the same picture.
    expect(find.text('Zeiterfassung'), findsWidgets);
    expect(find.byKey(const Key('splash')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splash')), findsNothing);
    expect(find.byKey(const Key('newEntry')), findsOneWidget);
  });

  testWidgets('offline at start: full offline screen, then the app by itself '
      'when back online', (tester) async {
    final network = FakeNetworkStatus(false);
    final contexts = FakeContextRepository()..result = const NoConnection();
    await pump(tester, signedIn(), contexts, network);

    expect(offlineScreen, findsWidgets);
    expect(find.text('Keine Verbindung'), findsWidgets);

    contexts.result = userContext();
    network.online = true;
    await tester.pumpAndSettle();
    expect(offlineScreen, findsNothing);
    expect(find.byKey(const Key('newEntry')), findsOneWidget);
  });

  testWidgets('losing the connection while using the app covers it with '
      'the offline screen; regaining it removes the screen', (tester) async {
    final network = FakeNetworkStatus();
    await pump(tester, signedIn(), FakeContextRepository(), network);
    expect(offlineScreen, findsNothing);

    network.online = false;
    await tester.pumpAndSettle();
    expect(offlineScreen, findsOneWidget);
    expect(find.text('Keine Verbindung'), findsOneWidget);

    network.online = true;
    await tester.pumpAndSettle();
    expect(offlineScreen, findsNothing);
    expect(find.byKey(const Key('newEntry')), findsOneWidget);
  });

  testWidgets('offline on the sign-in screen shows the offline screen', (
    tester,
  ) async {
    await pump(
      tester,
      FakeAuthRepository(),
      FakeContextRepository(),
      FakeNetworkStatus(false),
    );
    expect(offlineScreen, findsOneWidget);
  });

  testWidgets('a server error is not shown as offline', (tester) async {
    final contexts = FakeContextRepository()
      ..result = const ServerFailure('500');
    await pump(tester, signedIn(), contexts, FakeNetworkStatus());
    expect(offlineScreen, findsNothing);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });
}
