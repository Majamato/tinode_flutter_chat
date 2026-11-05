import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_player.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_recorder.dart';

import 'fake_attachment_picker.dart';
import 'fake_call_media.dart';
import 'fake_network_monitor.dart';
import 'fake_system_calls.dart';
import 'fake_tinode_session.dart';
import 'fake_voice_player.dart';
import 'fake_voice_recorder.dart';

final testConfig = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'test-key',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

/// The package's container, wired to [connector], disposed after the test.
/// A remembered user's session comes from [restorer], by default the
/// session [connector] hands out, restored. Caches live in [storeOpener],
/// by default a fresh one in memory, and files in [fileStoreOpener], also
/// in memory. Opened files go to [fileOpener], by default one that opens
/// nothing. Calls get fake media unless [callMedia] says otherwise, and
/// fake system call screens unless [systemCalls] does. Voice messages
/// record and play with fakes unless [voiceRecorder] and [voicePlayer]
/// say otherwise.
ProviderContainer createTestContainer({
  required SessionConnector connector,
  SessionRestorer? restorer,
  ChatStoreOpener? storeOpener,
  MemoryFileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  TinodeCredentials? credentials,
  CallMediaFactory? callMedia,
  SystemCalls? systemCalls,
  VoiceRecorderFactory? voiceRecorder,
  VoicePlayerFactory? voicePlayer,
  TinodeChatFeatures features = const TinodeChatFeatures(),
}) {
  final container = createTinodeContainer(
    config: testConfig,
    features: features,
    credentials: credentials,
    connector: connector,
    restorer:
        restorer ??
        (config, token) async =>
            (await connector(config) as FakeTinodeSession)..restoreWith(token),
    storeOpener: storeOpener ?? MemoryChatStoreOpener(),
    fileStoreOpener: fileStoreOpener ?? MemoryFileStoreOpener(),
    fileOpener: fileOpener ?? (_, {mimeType}) async => false,
    attachmentPicker: attachmentPicker ?? FakeAttachmentPicker(),
    network: FakeNetworkMonitor(),
    callMedia: callMedia ?? FakeCallMedia.new,
    systemCalls: systemCalls ?? FakeSystemCalls(),
    voiceRecorder: voiceRecorder ?? FakeVoiceRecorder.new,
    voicePlayer: voicePlayer ?? FakeVoicePlayer.new,
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets streams, microtasks and pending futures settle.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// A container whose session is already logged in to [session].
Future<ProviderContainer> loggedInContainer(
  FakeTinodeSession session, {
  CallMediaFactory? callMedia,
  SystemCalls? systemCalls,
  MemoryFileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  VoiceRecorderFactory? voiceRecorder,
  VoicePlayerFactory? voicePlayer,
  TinodeChatFeatures features = const TinodeChatFeatures(),
  ChatStoreOpener? storeOpener,
}) async {
  final container = createTestContainer(
    connector: connectTo(session),
    credentials: TinodeCredentials.token(session.token),
    callMedia: callMedia,
    systemCalls: systemCalls,
    fileStoreOpener: fileStoreOpener,
    fileOpener: fileOpener,
    attachmentPicker: attachmentPicker,
    voiceRecorder: voiceRecorder,
    voicePlayer: voicePlayer,
    features: features,
    storeOpener: storeOpener,
  )..listen(sessionControllerProvider, (_, _) {});
  await container.read(sessionControllerProvider.future);
  return container;
}
