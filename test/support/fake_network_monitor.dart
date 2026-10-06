import 'dart:async';

import 'package:tinode_flutter_chat/src/session/data/network_monitor.dart';

/// Network reports the test sends by hand.
final class FakeNetworkMonitor implements NetworkMonitor {
  final _changes = StreamController<bool>.broadcast(sync: true);

  void report({required bool available}) => _changes.add(available);

  void fail(Object error) => _changes.addError(error);

  @override
  Stream<bool> get changes => _changes.stream;
}
