import 'dart:developer';
import 'dart:io';

import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart'
    as callkit;
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/data/background_hang_up_entry.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// How long hanging up from the background may take before it gives up;
/// the server ends the call by itself anyway.
const backgroundHangUpTimeout = Duration(seconds: 15);

/// Has [hangUpDeclined] run when the user declines a call on the system's
/// screen while the app is closed. Only Android starts Dart for it; on iOS
/// the app runs whenever CallKit shows its call.
Future<void> registerBackgroundHangUp() async {
  if (!Platform.isAndroid) {
    return;
  }
  try {
    await callkit.FlutterCallkitIncoming.onBackgroundMessage(hangUpDeclined);
  } on Object catch (e, stackTrace) {
    log(
      'Could not register the background hang-up',
      name: 'tinode_flutter_chat',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Connects with [credentials], hangs up call [seq] in [topic] and closes
/// again. The callee may hang up without attaching the chat. Best effort:
/// failures are logged, and the call times out on the server instead.
Future<void> hangUpFromBackground(
  SessionConnector connect,
  HangUpCredentials credentials,
  String topic,
  int seq,
) async {
  TinodeSession? session;
  try {
    await () async {
      session = await connect(
        TinodeConfig(
          server: credentials.server,
          apiKey: credentials.apiKey,
          userAgent: credentials.userAgent,
        ),
      );
      await session!.loginToken(credentials.token);
      session!.sendCallEvent(topic, seq, CallEvent.hangUp);
    }().timeout(backgroundHangUpTimeout);
  } on Object catch (e, stackTrace) {
    log(
      'Could not hang up the declined call',
      name: 'tinode_flutter_chat',
      error: e,
      stackTrace: stackTrace,
    );
  } finally {
    await session?.close();
  }
}
