import 'package:connectivity_plus/connectivity_plus.dart';

/// The device's networks as the OS reports them: a hint that the link may
/// have changed, never proof that the server can be reached.
abstract interface class NetworkMonitor {
  /// One event per reported change; true while any network is up.
  Stream<bool> get changes;
}

/// Backed by OS callbacks (Android's default-network callback, iOS's
/// `NWPathMonitor`), so it costs no polling.
final class ConnectivityNetworkMonitor implements NetworkMonitor {
  // Android and iOS also report the current state on listen; that first
  // event costs at most one probe, and the web sends none to skip.
  @override
  Stream<bool> get changes => Connectivity().onConnectivityChanged.map(
    (networks) => !networks.contains(ConnectivityResult.none),
  );
}
