import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/app/presentation/isolate_port_names.dart';

void main() {
  const name = 'tinode_flutter_chat.test.port';
  tearDown(() => IsolateNameServer.removePortNameMapping(name));

  test("names ports in the process's IsolateNameServer, the newest wins", () {
    const names = IsolatePortNames();
    final first = ReceivePort();
    final second = ReceivePort();
    addTearDown(first.close);
    addTearDown(second.close);

    names
      ..register(first.sendPort, name)
      ..register(second.sendPort, name);
    expect(IsolateNameServer.lookupPortByName(name), second.sendPort);
    expect(names.lookup(name), second.sendPort);

    names.remove(name);
    expect(names.lookup(name), isNull);
  });
}
