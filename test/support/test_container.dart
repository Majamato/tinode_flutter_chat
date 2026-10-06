import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

import 'fake_network_monitor.dart';
import 'fake_tinode_session.dart';

final testConfig = TinodeConfig(
  server: Uri.parse('ws://localhost:6060'),
  apiKey: 'test-key',
  userAgent: 'tinode_flutter_chat-test/0.1',
);

/// The package's container, wired to [connector], disposed after the test.
ProviderContainer createTestContainer({
  required SessionConnector connector,
  TinodeCredentials? credentials,
}) {
  final container = createTinodeContainer(
    config: testConfig,
    credentials: credentials,
    connector: connector,
    network: FakeNetworkMonitor(),
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets streams, microtasks and pending futures settle.
Future<void> settle() => Future<void>.delayed(Duration.zero);

/// A container whose session is already logged in to [session].
Future<ProviderContainer> loggedInContainer(FakeTinodeSession session) async {
  final container = createTestContainer(
    connector: connectTo(session),
    credentials: TinodeCredentials.token(session.token),
  )..listen(sessionControllerProvider, (_, _) {});
  await container.read(sessionControllerProvider.future);
  return container;
}
