import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/application/file_download_controller.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/file_download_state.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/test_container.dart';

const ref = '/v0/file/s/report.pdf';

void main() {
  late FakeTinodeSession session;
  late List<LocalFile> opened;
  var openWorks = true;
  late ProviderContainer container;

  setUp(() async {
    session = FakeTinodeSession(chats: [chat(bob, name: 'Bob')]);
    session.files[ref] = pngBytes;
    opened = [];
    openWorks = true;
    container = await loggedInContainer(
      session,
      fileOpener: (file, {mimeType}) async {
        opened.add(file);
        return openWorks;
      },
    );
  });

  group('attachmentFile', () {
    test('downloads once for everyone watching', () async {
      container
        ..listen(attachmentFileProvider(ref), (_, _) {})
        ..listen(attachmentFileProvider(ref), (_, _) {});

      final file = await container.read(attachmentFileProvider(ref).future);

      expect(file.length, pngBytes.length);
      expect(session.calls.where((c) => c == 'download $ref'), hasLength(1));
    });

    test('a failed download loads again on the next connect', () async {
      session.failDownload = ServerUnreachableException(Exception('offline'));
      container.listen(attachmentFileProvider(ref), (_, _) {});
      await settle();
      await settle();
      expect(container.read(attachmentFileProvider(ref)).hasError, isTrue);

      session.emitStatus(const Connected());
      await settle();
      await settle();

      expect(
        container.read(attachmentFileProvider(ref)).value?.length,
        pngBytes.length,
      );
    });
  });

  group('FileDownloadController', () {
    test('downloads, then opens the file', () async {
      final states = <FileDownloadState>[];
      container.listen(
        fileDownloadControllerProvider(ref),
        (_, next) => states.add(next),
      );

      final result = await container
          .read(fileDownloadControllerProvider(ref).notifier)
          .open(mimeType: 'application/pdf');

      expect(result, isTrue);
      expect(states.first, isA<Downloading>());
      expect(states.last, isA<Downloaded>());
      expect(opened.single.length, pngBytes.length);
    });

    test('says when nothing opens it', () async {
      openWorks = false;
      container.listen(fileDownloadControllerProvider(ref), (_, _) {});
      final result = await container
          .read(fileDownloadControllerProvider(ref).notifier)
          .open();
      expect(result, isFalse);
    });

    test('a failed download is a failure state', () async {
      session.failDownload = const ServerException(404, 'not found');
      container.listen(fileDownloadControllerProvider(ref), (_, _) {});
      final result = await container
          .read(fileDownloadControllerProvider(ref).notifier)
          .open();

      expect(result, isNull);
      expect(
        container.read(fileDownloadControllerProvider(ref)),
        const DownloadFailed(ChatFailure.rejected),
      );
      expect(opened, isEmpty);
    });
  });

  group('sending', () {
    test('a file over the server limit is refused, with the limit', () async {
      session.serverInfo = const ServerInfo(
        version: '0.25',
        maxFileUploadSize: 4,
      );
      container.listen(sendControllerProvider(bob), (_, _) {});

      final queued = await container
          .read(sendControllerProvider(bob).notifier)
          .sendAttachment(pickedText('notes.txt', 'hello'));

      expect(queued, isFalse);
      expect(
        container.read(sendControllerProvider(bob)).error,
        isA<FileTooLargeException>().having((e) => e.limit, 'limit', 4),
      );
    });

    test('upload progress reaches the bubble', () async {
      final steps = session.uploadSteps = StreamController<int>();
      container.listen(sendControllerProvider(bob), (_, _) {});
      await container
          .read(sendControllerProvider(bob).notifier)
          .sendAttachment(pickedText('notes.txt', 'hello'));
      final outgoing = await container
          .read(activeSessionProvider)!
          .storedOutgoing(bob);
      final clientId = outgoing.single.clientId;
      final progress = <double?>[];
      container.listen(
        uploadProgressControllerProvider(bob, clientId),
        (_, next) => progress.add(next),
      );
      for (var i = 0; i < 10; i++) {
        await settle();
      }

      steps.add(1);
      await settle();
      expect(progress.last, 0.2);

      await steps.close();
      for (var i = 0; i < 10; i++) {
        await settle();
      }
      expect(progress.last, 1);
    });
  });
}
