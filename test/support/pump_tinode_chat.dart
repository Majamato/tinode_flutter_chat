import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import 'fake_attachment_picker.dart';
import 'fake_call_media.dart';
import 'fake_network_monitor.dart';
import 'fake_system_calls.dart';
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
  SystemCalls? systemCalls,
  ChatStoreOpener? storeOpener,
  MemoryFileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  VoidCallback? onLoggedOut,
  TinodeChatController? controller,
  TinodeChatFeatures features = const TinodeChatFeatures(),
  TinodeConfig? config,
  String? pushToken,
  ThemeData? theme,
  TinodeBubbleBuilder? bubbleBuilder,
  Widget? loginHeader,
  bool tabBar = false,
  TinodeAppearance? appearance,
  Widget? appearanceExtra,
  bool reduceMotion = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      // The login screen's bubbles drift for as long as it shows, so
      // `pumpAndSettle` would never settle on it; Reduce motion stills them.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: TinodeChat.withConnector(
        config: config ?? testConfig,
        connector: connectTo(session),
        restorer: restoreTo(session),
        storeOpener: storeOpener ?? MemoryChatStoreOpener(),
        fileStoreOpener: fileStoreOpener ?? MemoryFileStoreOpener(),
        fileOpener: fileOpener ?? (_, {mimeType}) async => false,
        attachmentPicker: attachmentPicker ?? FakeAttachmentPicker(),
        network: network ?? FakeNetworkMonitor(),
        callMedia: callMedia ?? FakeCallMedia.new,
        systemCalls: systemCalls ?? FakeSystemCalls(),
        credentials: credentials,
        onLoggedIn: onLoggedIn,
        onLoggedOut: onLoggedOut,
        controller: controller,
        features: features,
        pushToken: pushToken,
        bubbleBuilder: bubbleBuilder,
        loginHeader: loginHeader,
        tabBar: tabBar,
        appearance: appearance,
        appearanceExtra: appearanceExtra,
      ),
    ),
  );
  if (reduceMotion) {
    await tester.pumpAndSettle();
  } else {
    // Looping animations never settle: a second of frames instead.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}
