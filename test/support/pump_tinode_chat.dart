import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/gallery_saver.dart';
import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_speed_storage.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import 'fake_attachment_picker.dart';
import 'fake_call_media.dart';
import 'fake_media_compressor.dart';
import 'fake_network_monitor.dart';
import 'fake_system_calls.dart';
import 'fake_tinode_session.dart';
import 'fake_voice_player.dart';
import 'fake_voice_recorder.dart';
import 'memory_voice_speed_storage.dart';
import 'test_container.dart';

/// Pumps a [TinodeChat] in a `MaterialApp`, connected to [session], or
/// through [connector], for a test that needs another link after a logout.
Future<void> pumpTinodeChat(
  WidgetTester tester,
  FakeTinodeSession session, {
  TinodeCredentials? credentials,
  ValueChanged<LoginResult>? onLoggedIn,
  FakeNetworkMonitor? network,
  CallMediaFactory? callMedia,
  SystemCalls? systemCalls,
  SessionConnector? connector,
  ChatStoreOpener? storeOpener,
  MemoryFileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  MediaCompressor? mediaCompressor,
  GallerySaver? gallerySaver,
  VoiceRecorderFactory? voiceRecorder,
  VoicePlayerFactory? voicePlayer,
  VoiceSpeedStorage? voiceSpeedStorage,
  VoidCallback? onLoggedOut,
  TinodeChatController? controller,
  TinodeChatFeatures features = const TinodeChatFeatures(),
  TinodeConfig? config,
  String? pushToken,
  ThemeData? theme,
  TinodeChatIcons icons = const TinodeChatIcons(),
  TinodeBubbleBuilder? bubbleBuilder,
  TinodeAppBarBuilder? appBarBuilder,
  Widget? loginHeader,
  TinodeLoginBuilder? loginBuilder,
  bool tabBar = false,
  TinodeAppearance? appearance,
  Widget? appearanceExtra,
  bool reduceMotion = true,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      locale: locale,
      supportedLocales: locale == null
          ? const [Locale('en', 'US')]
          : TinodeChatStrings.supportedLocales,
      localizationsDelegates: locale == null
          ? null
          : GlobalMaterialLocalizations.delegates,
      // The call screens loop for as long as they show, so `pumpAndSettle`
      // would never settle on them; Reduce motion stills them.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: TinodeChat.withConnector(
        config: config ?? testConfig,
        connector: connector ?? connectTo(session),
        restorer: restoreTo(session),
        storeOpener: storeOpener ?? MemoryChatStoreOpener(),
        fileStoreOpener: fileStoreOpener ?? MemoryFileStoreOpener(),
        fileOpener: fileOpener ?? (_, {mimeType}) async => false,
        attachmentPicker: attachmentPicker ?? FakeAttachmentPicker(),
        mediaCompressor: mediaCompressor ?? FakeMediaCompressor(),
        gallerySaver: gallerySaver ?? (_, {required isVideo}) async {},
        network: network ?? FakeNetworkMonitor(),
        callMedia: callMedia ?? FakeCallMedia.new,
        systemCalls: systemCalls ?? FakeSystemCalls(),
        voiceRecorder: voiceRecorder ?? FakeVoiceRecorder.new,
        voicePlayer: voicePlayer ?? FakeVoicePlayer.new,
        voiceSpeedStorage: voiceSpeedStorage ?? MemoryVoiceSpeedStorage(),
        credentials: credentials,
        onLoggedIn: onLoggedIn,
        onLoggedOut: onLoggedOut,
        controller: controller,
        features: features,
        pushToken: pushToken,
        icons: icons,
        bubbleBuilder: bubbleBuilder,
        appBarBuilder: appBarBuilder,
        loginHeader: loginHeader,
        loginBuilder: loginBuilder,
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
