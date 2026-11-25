import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_context_cache.dart';
import '../data/user_context_repository.dart';
import '../model/user_context.dart';

final userContextRepositoryProvider = Provider<UserContextRepository>(
  (ref) => throw StateError('userContextRepositoryProvider not overridden'),
);

final userContextCacheProvider = Provider<UserContextCache>(
  (ref) => throw StateError('userContextCacheProvider not overridden'),
);

/// Loads the user's settings and access: cache first for a fast start,
/// then the network. A failed refresh keeps the cached value.
class UserContextController {
  UserContextController(this._repo, this._cache);

  final UserContextRepository _repo;
  final UserContextCache _cache;

  /// Emits the cached context (if any), then the fresh one.
  /// Throws only when there is no cache and the network fails.
  Stream<UserContext> load(String userId) async* {
    final cached = await _cache.read(userId);
    if (cached != null) yield cached;
    try {
      final fresh = await _repo.load(userId);
      await _cache.write(fresh);
      yield fresh;
    } on Object {
      if (cached == null) rethrow;
    }
  }

  Future<void> clear() => _cache.clear();
}

final userContextControllerProvider = Provider<UserContextController>(
  (ref) => UserContextController(
    ref.watch(userContextRepositoryProvider),
    ref.watch(userContextCacheProvider),
  ),
);
