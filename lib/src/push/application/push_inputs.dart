import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/push/data/port_names.dart';

part 'push_inputs.g.dart';

/// Where the app's session takes the pushes of the push service's
/// background isolate (`PushRelay`); `TinodeChat` overrides it with the
/// process's `IsolateNameServer`.
@Riverpod(keepAlive: true)
PortNames pushPortNames(Ref ref) => MemoryPortNames();
