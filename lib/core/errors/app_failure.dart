import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Every error the UI can show. Repositories turn exceptions into one of
/// these with [AppFailure.from]; screens never see backend exceptions.
sealed class AppFailure implements Exception {
  const AppFailure();

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is SocketException ||
        error is TimeoutException ||
        error is AuthRetryableFetchException) {
      return const NoConnection();
    }
    if (error is AuthException) {
      if (error.code == 'invalid_credentials' ||
          error.statusCode == '400' &&
              error.message.contains('Invalid login')) {
        return const InvalidCredentials();
      }
      if (error.code == 'user_banned') return const AccountDisabled();
      if (error is AuthSessionMissingException ||
          error.code == 'refresh_token_not_found' ||
          error.code == 'session_expired' ||
          error.statusCode == '401') {
        return const SessionExpired();
      }
      return ServerFailure(error.code ?? error.statusCode);
    }
    if (error is PostgrestException) {
      // 42501: insufficient privilege (row-level security), PGRST301: bad JWT.
      if (error.code == '42501') return const AccessDenied();
      if (error.code == 'PGRST301') return const SessionExpired();
      return ServerFailure(error.code);
    }
    return const UnknownFailure();
  }
}

final class NoConnection extends AppFailure {
  const NoConnection();
}

final class InvalidCredentials extends AppFailure {
  const InvalidCredentials();
}

final class AccountDisabled extends AppFailure {
  const AccountDisabled();
}

final class SessionExpired extends AppFailure {
  const SessionExpired();
}

final class AccessDenied extends AppFailure {
  const AccessDenied();
}

/// The backend answered with an error. [code] is for support, never shown
/// raw to the user and never contains personal data.
final class ServerFailure extends AppFailure {
  const ServerFailure(this.code);
  final String? code;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure();
}
