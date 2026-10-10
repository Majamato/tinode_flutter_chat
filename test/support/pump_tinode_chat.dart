import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import 'fake_attachment_picker.dart';
import 'fake_call_media.dart';
import 'fake_network_monitor.dart';
import 'fake_tinode_session.dart';
import 'test_container.dart';

/// Pumps a [TinodeChat] in a `MaterialApp`, connected to [session].
Future<void> pumpTinodeChat(
  WidgetTester tester,
  FakeTinodeSession session, {
  TinodeCredentials? credentials,
  ValueChanged<LoginResult>? onLoggedIn,
  FakeNetworkMonitor? network,
  CallMediaFactory? callMedia,
  ChatStoreOpener? storeOpener,
  MemoryFileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  VoidCallback? onLoggedOut,
  TinodeChatController? controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TinodeChat.withConnector(
        config: testConfig,
        connector: connectTo(session),
        restorer: restoreTo(session),
        storeOpener: storeOpener ?? MemoryChatStoreOpener(),
        fileStoreOpener: fileStoreOpener ?? MemoryFileStoreOpener(),
        fileOpener: fileOpener ?? (_, {mimeType}) async => false,
        attachmentPicker: attachmentPicker ?? FakeAttachmentPicker(),
        network: network ?? FakeNetworkMonitor(),
        callMedia: callMedia ?? FakeCallMedia.new,
        credentials: credentials,
        onLoggedIn: onLoggedIn,
        onLoggedOut: onLoggedOut,
        controller: controller,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
