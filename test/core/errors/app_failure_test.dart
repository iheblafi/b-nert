import 'dart:async';
import 'dart:io';

import 'package:flutter_mobile/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('network errors become NoConnection', () {
    expect(AppFailure.from(const SocketException('x')), isA<NoConnection>());
    expect(AppFailure.from(TimeoutException('x')), isA<NoConnection>());
    expect(AppFailure.from(AuthRetryableFetchException()), isA<NoConnection>());
  });

  test('wrong credentials', () {
    expect(
      AppFailure.from(
        const AuthApiException(
          'Invalid login credentials',
          code: 'invalid_credentials',
        ),
      ),
      isA<InvalidCredentials>(),
    );
  });

  test('disabled account and expired session', () {
    expect(
      AppFailure.from(const AuthApiException('banned', code: 'user_banned')),
      isA<AccountDisabled>(),
    );
    expect(
      AppFailure.from(
        const AuthApiException('x', code: 'refresh_token_not_found'),
      ),
      isA<SessionExpired>(),
    );
  });

  test('database errors', () {
    expect(
      AppFailure.from(const PostgrestException(message: 'rls', code: '42501')),
      isA<AccessDenied>(),
    );
    final f = AppFailure.from(
      const PostgrestException(message: 'm', code: '23505'),
    );
    expect(f, isA<ServerFailure>());
    expect((f as ServerFailure).code, '23505');
  });

  test('anything else is UnknownFailure, and failures pass through', () {
    expect(AppFailure.from(StateError('x')), isA<UnknownFailure>());
    const same = InvalidCredentials();
    expect(identical(AppFailure.from(same), same), isTrue);
  });
}
