import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/voice/data/file_voice_speed_storage.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('voice_speed_test');
  });

  tearDown(() => directory.delete(recursive: true));

  FileVoiceSpeedStorage storage() =>
      FileVoiceSpeedStorage(directory: () async => directory);

  File file() => File('${directory.path}/tinode_voice_speed.json');

  test('nothing saved reads as normal', () async {
    expect(await storage().read(), VoiceSpeed.normal);
  });

  test('reads back what it wrote, the last write winning', () async {
    final writer = storage();
    await Future.wait([
      writer.write(VoiceSpeed.fastest),
      writer.write(VoiceSpeed.fast),
    ]);

    expect(await storage().read(), VoiceSpeed.fast);
  });

  test('a broken file reads as normal', () async {
    file().writeAsStringSync('{');
    expect(await storage().read(), VoiceSpeed.normal);
  });

  test('an unknown speed reads as normal', () async {
    file().writeAsStringSync('{"speed": "ludicrous"}');
    expect(await storage().read(), VoiceSpeed.normal);
  });
}
