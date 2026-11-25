import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_mobile/features/user_context/data/user_context_cache.dart';
import 'package:flutter_mobile/features/user_context/data/user_context_repository.dart';
import 'package:flutter_mobile/features/user_context/model/user_context.dart';
import 'package:flutter_mobile/features/user_context/state/user_context_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/fixtures.dart';

class MockRepo extends Mock implements UserContextRepository {}

void main() {
  late MockRepo repo;
  late UserContextCache cache;
  late UserContextController controller;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repo = MockRepo();
    cache = UserContextCache(SharedPreferencesAsync());
    controller = UserContextController(repo, cache);
  });

  test('first start: loads from network and caches', () async {
    when(() => repo.load('u1')).thenAnswer((_) async => userContext());
    final emitted = await controller.load('u1').toList();
    expect(emitted, hasLength(1));
    expect(await cache.read('u1'), isNotNull);
  });

  test('later start: cached value first, then fresh', () async {
    await cache.write(userContext(supervises: false));
    when(() => repo.load('u1'))
        .thenAnswer((_) async => userContext(supervises: true));
    final emitted = await controller.load('u1').toList();
    expect(emitted.map((c) => c.access.supervisesSomeone), [false, true]);
  });

  test('network failure keeps the cached value', () async {
    await cache.write(userContext());
    when(() => repo.load('u1')).thenThrow(const NoConnection());
    final emitted = await controller.load('u1').toList();
    expect(emitted, hasLength(1));
  });

  test('network failure without cache is an error', () {
    when(() => repo.load('u1')).thenThrow(const NoConnection());
    expect(controller.load('u1').toList(), throwsA(isA<NoConnection>()));
  });

  test('another user never gets the cached rights', () async {
    await cache.write(userContext(userId: 'someone-else'));
    expect(await cache.read('u1'), isNull);
  });

  test('clear removes the cache', () async {
    await cache.write(userContext());
    await controller.clear();
    expect(await cache.read('u1'), isNull);
  });

  test('emitted types', () async {
    when(() => repo.load('u1')).thenAnswer((_) async => userContext());
    expect(await controller.load('u1').first, isA<UserContext>());
  });
}
