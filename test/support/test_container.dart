import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import 'fake_call_media.dart';
import 'fake_network_monitor.dart';
import 'fake_tinode_session.dart';

final testConfig = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'test-key',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

/// The package's container, wired to [connector], disposed after the test.
/// A remembered user's session comes from [restorer], by default the
/// session [connector] hands out, restored. Caches live in [storeOpener],
/// by default a fresh one in memory. Calls get fake media unless
/// [callMedia] says otherwise.
ProviderContainer createTestContainer({
  required SessionConnector connector,
  SessionRestorer? restorer,
  ChatStoreOpener? storeOpener,
  TinodeCredentials? credentials,
  CallMediaFactory? callMedia,
}) {
  final container = createTinodeContainer(
    config: testConfig,
    credentials: credentials,
    connector: connector,
    restorer:
        restorer ??
        (config, token) async =>
            (await connector(config) as FakeTinodeSession)..restoreWith(token),
    storeOpener: storeOpener ?? MemoryChatStoreOpener(),
    network: FakeNetworkMonitor(),
    callMedia: callMedia ?? FakeCallMedia.new,
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
}) async {
  final container = createTestContainer(
    connector: connectTo(session),
    credentials: TinodeCredentials.token(session.token),
    callMedia: callMedia,
  )..listen(sessionControllerProvider, (_, _) {});
  await container.read(sessionControllerProvider.future);
  return container;
}
