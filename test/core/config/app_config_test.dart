import 'package:flutter_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasBackend is false without url or key', () {
    expect(
      const AppConfig(supabaseUrl: '', supabaseAnonKey: 'k').hasBackend,
      isFalse,
    );
    expect(
      const AppConfig(supabaseUrl: 'https://x', supabaseAnonKey: '').hasBackend,
      isFalse,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'https://x',
        supabaseAnonKey: 'k',
      ).hasBackend,
      isTrue,
    );
  });
}
