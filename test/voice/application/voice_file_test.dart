import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/voice/application/voice_file.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

void main() {
  const heard = RefVoiceSource('/v0/file/s/heard.m4a');

  late FakeTinodeSession session;
  late MemoryFileStoreOpener files;
  late ProviderContainer container;

  Future<LocalFile?> voiceFile(VoiceSource source) {
    container.listen(voiceFileProvider(source), (_, _) {});
    return container.read(voiceFileProvider(source).future);
  }

  setUp(() async {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    session.files[heard.ref] = Uint8List.fromList([1, 2, 3]);
    files = MemoryFileStoreOpener();
    container = await loggedInContainer(session, fileStoreOpener: files);
  });

  test('a received one downloads once, among the kept files', () async {
    expect((await voiceFile(heard))!.length, 3);
    final store = files.stores.values.single;
    expect(store.isKept(session.resolveFile(heard.ref)!), isTrue);

    container.invalidate(voiceFileProvider(heard));
    await voiceFile(heard);
    expect(session.calls.where((c) => c.startsWith('download')), hasLength(1));
  });

  test('one missing on the server is an error', () async {
    await expectLater(
      voiceFile(const RefVoiceSource('/v0/file/s/gone.m4a')),
      throwsA(anything),
    );
  });

  test("one of the user's comes from its staged copy", () async {
    session.holdUpload = Completer<void>();
    final sent = await container
        .read(activeSessionProvider)!
        .sendAttachment(bob, pickedFile('voice.m4a', [1, 2]));
    final source = StagedVoiceSource(sent.attachment!.stagedId);
    expect((await voiceFile(source))!.length, 2);
    expect(await voiceFile(const StagedVoiceSource('1_gone.m4a')), isNull);
  });

  test('one inside the message is its bytes', () async {
    final bytes = Uint8List.fromList([7, 8]);
    final file = await voiceFile(InlineVoiceSource(id: 'bob:1', bytes: bytes));
    expect(file!.bytes, bytes);
  });
}
