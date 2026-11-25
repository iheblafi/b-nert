import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint, face or the device's screen lock.
abstract interface class Biometrics {
  /// True when the phone has a secure screen lock: fingerprint, face, PIN,
  /// pattern or password. Android's own "biometrics enrolled" check comes
  /// back empty on some phones (Xiaomi) although a fingerprint is set up,
  /// and unlocking falls back to the screen lock anyway.
  Future<bool> isAvailable();

  /// Shows the system prompt. False when cancelled or failed.
  Future<bool> authenticate(String reason);
}

class DeviceBiometrics implements Biometrics {
  final _auth = LocalAuthentication();
  static const _credential = MethodChannel('bamsenet/device_credential');

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object catch (e) {
      debugPrint('biometrics: availability check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Device PIN or pattern stays allowed, so a wet finger or a phone
      // without fingerprint never locks anyone out of their own app.
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      debugPrint('biometrics: prompt failed: ${e.code.name} ${e.description}');
      if (_userStopped.contains(e.code)) return false;
      // The prompt could not offer anything usable, typically no
      // fingerprint enrolled and the phone not allowing PIN in the prompt.
      return _confirmScreenLock(reason);
    } on Object catch (e) {
      debugPrint('biometrics: prompt failed: $e');
      return _confirmScreenLock(reason);
    }
  }

  static const _userStopped = {
    LocalAuthExceptionCode.userCanceled,
    LocalAuthExceptionCode.systemCanceled,
    LocalAuthExceptionCode.timeout,
    LocalAuthExceptionCode.authInProgress,
  };

  /// Android's own "confirm your PIN, pattern or password" screen.
  Future<bool> _confirmScreenLock(String reason) async {
    if (!Platform.isAndroid) return false;
    try {
      return await _credential.invokeMethod<bool>('confirm', {
            'title': reason,
            'description': null,
          }) ??
          false;
    } on Object catch (e) {
      debugPrint('biometrics: screen lock confirmation failed: $e');
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((_) => DeviceBiometrics());

final biometricsAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricsProvider).isAvailable(),
);
