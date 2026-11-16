import 'dart:isolate';

/// Where the isolates of this process find each other's ports by name.
/// The app's is Flutter's `IsolateNameServer` (`IsolatePortNames`); tests
/// keep one in memory.
abstract interface class PortNames {
  SendPort? lookup(String name);

  /// Names [port] [name], in place of any port named so before.
  void register(SendPort port, String name);

  void remove(String name);
}

/// [PortNames] in memory, seen only by those holding this instance: a
/// container with no `TinodeChat` around it, or a test.
final class MemoryPortNames implements PortNames {
  final _ports = <String, SendPort>{};

  @override
  SendPort? lookup(String name) => _ports[name];

  @override
  void register(SendPort port, String name) => _ports[name] = port;

  @override
  void remove(String name) => _ports.remove(name);
}
