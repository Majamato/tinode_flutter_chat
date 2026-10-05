import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_credentials.dart';

/// The composition root: one container per `TinodeChat`, owned by it.
///
/// Automatic retry is off. Retrying a rejected login or a connect would
/// hide failures the user has to act on, and every retry here is explicit.
ProviderContainer createTinodeContainer({
  required TinodeConfig config,
  TinodeCredentials? credentials,
  SessionConnector? connector,
}) => ProviderContainer(
  overrides: [
    tinodeConfigProvider.overrideWithValue(config),
    initialCredentialsProvider.overrideWithValue(credentials),
    if (connector != null)
      sessionConnectorProvider.overrideWithValue(connector),
  ],
  retry: (_, _) => null,
);
