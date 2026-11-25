import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_failure.dart';
import '../../core/security/biometrics.dart';
import '../../core/session/secret_store.dart';
import '../auth/state/session.dart';

/// Biometric unlock and sign-in.
///
/// - Lock: the session stays in the keystore as before; the lock decides
///   whether the app may show it (cold start, 2 minutes in background).
/// - Sign-in after signing out: signing out ends the session on the
///   server, so the e-mail and password are kept in the keystore while the
///   lock is on, and only released after fingerprint or screen lock.
///   Turning the lock off, another person signing in, or a changed
///   password deletes them.
class AppLockStore {
  AppLockStore(this._prefs);

  static const enabledKey = 'bamsenet.app_lock';
  static const offeredKey = 'bamsenet.app_lock_offered';
  final SharedPreferencesAsync _prefs;

  Future<bool> enabled() async => await _prefs.getBool(enabledKey) ?? false;
  Future<void> setEnabled(bool on) => _prefs.setBool(enabledKey, on);

  /// Whether the user was already asked after signing in.
  Future<bool> offered() async => await _prefs.getBool(offeredKey) ?? false;
  Future<void> setOffered(bool asked) => _prefs.setBool(offeredKey, asked);
}

typedef Credentials = ({String email, String password});

/// E-mail and password in the keystore, for sign-in by fingerprint.
class SavedSignIn {
  SavedSignIn(this._secrets);

  static const key = 'bamsenet.saved_sign_in';
  final SecretStore _secrets;

  Future<Credentials?> read() async {
    final raw = await _secrets.read(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (email: j['email'] as String, password: j['password'] as String);
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> write(Credentials c) => _secrets.write(
    key,
    jsonEncode({'email': c.email, 'password': c.password}),
  );

  Future<void> clear() => _secrets.delete(key);
}

final appLockStoreProvider = Provider<AppLockStore>(
  (_) => AppLockStore(SharedPreferencesAsync()),
);

final savedSignInProvider = Provider<SavedSignIn>(
  (ref) => SavedSignIn(ref.watch(secretStoreProvider)),
);

/// Read in main() before the first frame, so a restored session is never
/// shown unlocked for a moment.
final initialAppLockProvider = Provider<bool>((_) => false);

/// Whether a sign-in is saved; read in main() with the lock setting.
final initialSavedSignInProvider = Provider<bool>((_) => false);

final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

class AppLockState {
  const AppLockState({
    required this.enabled,
    required this.locked,
    this.offerPending = false,
    this.hasSavedSignIn = false,
  });

  final bool enabled;
  final bool locked;

  /// Signed in with the password just now: offer the lock once.
  final bool offerPending;

  /// Sign-in by fingerprint is possible on the sign-in screen.
  final bool hasSavedSignIn;

  bool get canQuickSignIn => enabled && hasSavedSignIn;

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    bool? offerPending,
    bool? hasSavedSignIn,
  }) => AppLockState(
    enabled: enabled ?? this.enabled,
    locked: locked ?? this.locked,
    offerPending: offerPending ?? this.offerPending,
    hasSavedSignIn: hasSavedSignIn ?? this.hasSavedSignIn,
  );
}

enum QuickSignInResult { signedIn, cancelled, passwordChanged }

class AppLockController extends Notifier<AppLockState> {
  /// Back from the background after this long: lock again.
  static const relockAfter = Duration(minutes: 2);

  DateTime? _pausedAt;

  /// The password typed at the last sign-in, kept in memory only, so that
  /// turning the lock on afterwards can save it.
  Credentials? _typed;
  Future<void>? _afterSignIn;

  AppLockStore get _store => ref.read(appLockStoreProvider);
  SavedSignIn get _saved => ref.read(savedSignInProvider);

  @override
  AppLockState build() {
    ref.listen(sessionProvider, (prev, next) {
      if (next is SignedOut && prev is! SignedOut) {
        // Signing out keeps the lock and the saved sign-in, so the next
        // sign-in can be by fingerprint.
        _typed = null;
        state = state.copyWith(locked: false);
      } else if (next is SignedIn && prev is! SignedIn && _typed != null) {
        _afterSignIn = _onPasswordSignIn(_typed!);
      }
    });
    final enabled = ref.read(initialAppLockProvider);
    final restored = ref.read(authRepositoryProvider).currentUser != null;
    return AppLockState(
      enabled: enabled,
      locked: enabled && restored,
      hasSavedSignIn: ref.read(initialSavedSignInProvider),
    );
  }

  Future<void> _onPasswordSignIn(Credentials typed) async {
    if (!state.enabled) return;
    final saved = await _saved.read();
    if (saved != null && saved.email != typed.email) {
      // Someone else on this phone: their choice, not the last person's.
      await _saved.clear();
      await _store.setEnabled(false);
      await _store.setOffered(false);
      state = state.copyWith(enabled: false, hasSavedSignIn: false);
      return;
    }
    await _saved.write(typed);
    state = state.copyWith(hasSavedSignIn: true);
  }

  Future<bool> unlock(String reason) async {
    final ok = await ref.read(biometricsProvider).authenticate(reason);
    if (ok && ref.mounted) state = state.copyWith(locked: false);
    return ok;
  }

  /// Asks for the fingerprint first, so nobody turns it on by accident.
  Future<bool> enable(String reason) async {
    final ok = await ref.read(biometricsProvider).authenticate(reason);
    if (!ok || !ref.mounted) return false;
    await _store.setEnabled(true);
    final typed = _typed;
    if (typed != null) await _saved.write(typed);
    state = state.copyWith(
      enabled: true,
      locked: false,
      hasSavedSignIn: typed != null || state.hasSavedSignIn,
    );
    return true;
  }

  Future<void> disable() async {
    await _store.setEnabled(false);
    await _saved.clear();
    state = state.copyWith(
      enabled: false,
      locked: false,
      hasSavedSignIn: false,
    );
  }

  /// Sign in with the saved e-mail and password after the fingerprint.
  /// Throws [AppFailure] for problems the user must see (no connection).
  Future<QuickSignInResult> quickSignIn(String reason) async {
    final saved = await _saved.read();
    if (saved == null) {
      state = state.copyWith(hasSavedSignIn: false);
      return QuickSignInResult.passwordChanged;
    }
    if (!await ref.read(biometricsProvider).authenticate(reason)) {
      return QuickSignInResult.cancelled;
    }
    _typed = saved;
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: saved.email, password: saved.password);
      return QuickSignInResult.signedIn;
    } on InvalidCredentials {
      _typed = null;
      await _saved.clear();
      state = state.copyWith(hasSavedSignIn: false);
      return QuickSignInResult.passwordChanged;
    } on AppFailure {
      _typed = null;
      rethrow;
    }
  }

  void signedInWithPassword(String email, String password) {
    _typed = (email: email.trim(), password: password);
    state = state.copyWith(offerPending: true);
  }

  void signInFailed() {
    _typed = null;
    state = state.copyWith(offerPending: false);
  }

  /// Whether to show the offer now. Asks at most once per sign-in, and
  /// only when the device can do it.
  Future<bool> takeOffer() async {
    await _afterSignIn;
    if (!state.offerPending) return false;
    state = state.copyWith(offerPending: false);
    if (state.enabled || await _store.offered()) return false;
    if (!await ref.read(biometricsProvider).isAvailable()) return false;
    await _store.setOffered(true);
    return true;
  }

  void paused() => _pausedAt = ref.read(clockProvider)();

  void resumed() {
    final since = _pausedAt;
    _pausedAt = null;
    if (since == null || !state.enabled || state.locked) return;
    if (ref.read(sessionProvider) is SignedOut) return;
    if (ref.read(clockProvider)().difference(since) >= relockAfter) {
      state = state.copyWith(locked: true);
    }
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
