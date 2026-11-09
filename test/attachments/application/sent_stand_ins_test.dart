import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/application/sent_stand_ins.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

void main() {
  LocalFile picture(int byte) => LocalFile.inMemory(Uint8List.fromList([byte]));

  test("gives back the picture a message's bubble left", () {
    final left = picture(1);
    final standIns = SentStandIns()..leave('c1', left);

    expect(standIns['c1'], same(left));
    expect(standIns['c2'], isNull);
  });

  test('the latest picture left counts', () {
    final latest = picture(2);
    final standIns = SentStandIns()
      ..leave('c1', picture(1))
      ..leave('c1', latest);

    expect(standIns['c1'], same(latest));
  });

  test('removing forgets that picture and no other', () {
    final other = picture(2);
    final standIns = SentStandIns()
      ..leave('c1', picture(1))
      ..leave('c2', other)
      ..remove('c1');

    expect(standIns['c1'], isNull);
    expect(standIns['c2'], same(other));
  });

  test('removing a picture never left does nothing', () {
    final left = picture(1);
    final standIns = SentStandIns()
      ..leave('c1', left)
      ..remove('unknown');

    expect(standIns['c1'], same(left));
  });

  test('keeps the latest only, one left again counting as new', () {
    final standIns = SentStandIns();
    for (var i = 0; i < SentStandIns.capacity; i++) {
      standIns.leave('c$i', picture(i));
    }

    standIns
      ..leave('c0', picture(0))
      ..leave('more', picture(99));

    expect(standIns['c0'], isNotNull);
    expect(standIns['c1'], isNull);
    expect(standIns['more'], isNotNull);
  });
}
