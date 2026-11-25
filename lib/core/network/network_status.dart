import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the phone has a network. A network does not guarantee the
/// backend is reachable; requests still report NoConnection themselves.
abstract interface class NetworkStatus {
  Future<bool> isOnline();

  /// Emits on every change.
  Stream<bool> get changes;
}

class DeviceNetworkStatus implements NetworkStatus {
  final _connectivity = Connectivity();

  static bool _online(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

final networkStatusProvider = Provider<NetworkStatus>(
  (_) => DeviceNetworkStatus(),
);

/// Current state, then every change.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final status = ref.watch(networkStatusProvider);
  yield await status.isOnline();
  yield* status.changes;
});
