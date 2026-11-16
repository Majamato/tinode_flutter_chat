import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_list_controller.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/push/application/push_inputs.dart';
import 'package:tinode_flutter_chat/src/push/data/push_relay_port.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/background_policy.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';

part 'push_relay.g.dart';

/// How long the app's session may take over a push handed to it, within
/// the push service's own budget for the handler.
const appPushTimeout = Duration(seconds: 12);

/// Takes the pushes the host's push service receives in its background
/// isolate while the app lives in this process (`TinodeMessages`), through
/// the port it names after the server ([pushPortNamesProvider]): the
/// logged-in session handles them on its own connection, so no second
/// login, connection or writer of the cache starts. A suspended session
/// wakes for one grace period to fetch.
@Riverpod(keepAlive: true)
class PushRelay extends _$PushRelay {
  @override
  void build() {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      return;
    }
    final server = ref.watch(tinodeConfigProvider).server;
    final port = AppPushPort.open(
      ref.watch(pushPortNamesProvider),
      server,
      (push) => _apply(session, push),
    );
    ref.onDispose(port.close);
  }

  Future<TinodePushNames> _apply(ChatSession session, TinodePush push) async {
    if (push is MessagePush || push is SubscriptionPush) {
      ref.read(backgroundPolicyProvider.notifier).wake();
    }
    try {
      await session.applyPush(push).timeout(appPushTimeout);
    } on Object catch (e, stackTrace) {
      log(
        'Could not catch up after a push',
        name: 'tinode_flutter_chat',
        error: e,
        stackTrace: stackTrace,
      );
    }
    if (push case ReadPush(:final topic, seq: final seq?) when ref.mounted) {
      ref.read(chatListControllerProvider.notifier).markRead(topic, seq);
    }
    return session.storedPushNames(push);
  }
}
