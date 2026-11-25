import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release builds use only the main manifest. A permission that lives only
/// in the debug manifest works in development and fails in the store app.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');

  for (final permission in [
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.USE_BIOMETRIC',
  ]) {
    test('release manifest declares $permission', () {
      expect(manifest.readAsStringSync(), contains('"$permission"'));
    });
  }
}
