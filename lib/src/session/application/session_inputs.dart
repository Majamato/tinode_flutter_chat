import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

part 'session_inputs.g.dart';

/// The server to connect to; `createTinodeContainer` overrides it.
@Riverpod(keepAlive: true)
TinodeConfig tinodeConfig(Ref ref) =>
    throw UnimplementedError('Overridden by createTinodeContainer.');

/// The credentials the host passed to `TinodeChat`, if any.
@Riverpod(keepAlive: true)
TinodeCredentials? initialCredentials(Ref ref) => null;

/// How sessions are opened; tests override it with a fake.
@Riverpod(keepAlive: true)
SessionConnector sessionConnector(Ref ref) => ClientTinodeSession.connect;
