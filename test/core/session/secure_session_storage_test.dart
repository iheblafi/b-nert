import 'package:flutter_mobile/core/session/secure_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/memory_secret_store.dart';

void main() {
  late MemorySecretStore store;
  late SecureSessionStorage storage;

  setUp(() {
    store = MemorySecretStore();
    storage = SecureSessionStorage(store);
  });

  test('starts empty', () async {
    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('persists, reads back and removes the session', () async {
    await storage.persistSession('{"refresh_token":"r"}');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), '{"refresh_token":"r"}');
    expect(await storage.hasValidShape(), isTrue);

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
    expect(store.values, isEmpty);
  });

  test('a corrupt stored session is reported as invalid', () async {
    await storage.persistSession('not json');
    expect(await storage.hasValidShape(), isFalse);
  });
}
