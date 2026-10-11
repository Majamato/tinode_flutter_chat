import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/push/application/push_token_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

part 'push_registration.g.dart';

/// Hands the host's push token to each logged-in session, and every change
/// of it. The client sends it again after each reconnect, and after an
/// offline start once the server answers.
///
/// Logging out removes it from the server first: see
/// `SessionController.logout`.
@Riverpod(keepAlive: true)
class PushRegistration extends _$PushRegistration {
  @override
  void build() {
    final token = ref.watch(pushTokenControllerProvider);
    final session = ref.watch(activeSessionProvider);
    if (session != null) {
      unawaited(_register(session, token));
    }
  }

  /// A refused token must not break the chat: the next session tries again.
  static Future<void> _register(TinodeSession session, String? token) async {
    try {
      await session.setDeviceToken(token);
    } on TinodeException catch (e, stackTrace) {
      log(
        'Could not register the push token',
        name: 'tinode_flutter_chat',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
