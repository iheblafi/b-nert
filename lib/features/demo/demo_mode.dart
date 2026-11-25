import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';

/// Sample data on or off. On by default until the real data screens
/// (sprint 2 to 4) exist; build with --dart-define=DEMO_DATA=false to start
/// with it off.
class DemoModeController extends Notifier<bool> {
  static const key = 'bamsenet.demo_data';
  static const byDefault = bool.fromEnvironment(
    'DEMO_DATA',
    defaultValue: true,
  );

  @override
  bool build() {
    SharedPreferencesAsync().getBool(key).then((v) {
      if (v != null && ref.mounted && v != state) state = v;
    });
    return byDefault;
  }

  Future<void> set(bool on) async {
    state = on;
    await SharedPreferencesAsync().setBool(key, on);
  }
}

final demoModeProvider = NotifierProvider<DemoModeController, bool>(
  DemoModeController.new,
);

/// Clock for the sample data; tests pin it.
final demoNowProvider = Provider<DateTime Function()>((_) => DateTime.now);

final demoDataProvider = Provider<DemoData?>(
  (ref) => ref.watch(demoModeProvider)
      ? DemoData.generate(ref.watch(demoNowProvider)())
      : null,
);
