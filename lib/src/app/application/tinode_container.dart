import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_inputs.dart';
import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_opener.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_inputs.dart';
import 'package:tinode_flutter_chat/src/calls/domain/call_media.dart';
import 'package:tinode_flutter_chat/src/offline/application/offline_inputs.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/session/data/network_monitor.dart';
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
  SessionRestorer? restorer,
  ChatStoreOpener? storeOpener,
  FileStoreOpener? fileStoreOpener,
  FileOpener? fileOpener,
  AttachmentPicker? attachmentPicker,
  NetworkMonitor? network,
  CallMediaFactory? callMedia,
}) => ProviderContainer(
  overrides: [
    tinodeConfigProvider.overrideWithValue(config),
    initialCredentialsProvider.overrideWithValue(credentials),
    ?_override(connector, sessionConnectorProvider.overrideWithValue),
    ?_override(restorer, sessionRestorerProvider.overrideWithValue),
    ?_override(storeOpener, chatStoreOpenerProvider.overrideWithValue),
    ?_override(fileStoreOpener, fileStoreOpenerProvider.overrideWithValue),
    ?_override(fileOpener, fileOpenerProvider.overrideWithValue),
    ?_override(attachmentPicker, attachmentPickerProvider.overrideWithValue),
    ?_override(network, networkMonitorProvider.overrideWithValue),
    ?_override(callMedia, callMediaFactoryProvider.overrideWithValue),
  ],
  retry: (_, _) => null,
);

/// Overrides a seam only when the caller supplied a [value] for it.
Override? _override<T extends Object>(
  T? value,
  Override Function(T value) override,
) => value == null ? null : override(value);
