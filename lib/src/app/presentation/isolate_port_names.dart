import 'dart:isolate';
import 'dart:ui';

import 'package:tinode_flutter_chat/src/push/data/port_names.dart';

/// [PortNames] in Flutter's [IsolateNameServer], which every isolate of the
/// process shares: the app's and the push service's background one.
final class IsolatePortNames implements PortNames {
  const IsolatePortNames();

  @override
  SendPort? lookup(String name) => IsolateNameServer.lookupPortByName(name);

  @override
  void register(SendPort port, String name) {
    IsolateNameServer.removePortNameMapping(name);
    IsolateNameServer.registerPortWithName(port, name);
  }

  @override
  void remove(String name) => IsolateNameServer.removePortNameMapping(name);
}
