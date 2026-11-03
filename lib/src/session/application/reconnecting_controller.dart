import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';
import 'package:tinode_flutter_chat/src/session/application/network_policy.dart';

part 'reconnecting_controller.g.dart';

/// True while the client restores a dropped link of the logged-in session.
@Riverpod(keepAlive: true)
class ReconnectingController extends _$ReconnectingController {
  @override
  bool build() {
    final session = ref.watch(activeSessionProvider);
    if (session == null) {
      return false;
    }
    final statuses = session.statusChanges.listen(
      (status) => state = status is Reconnecting,
    );
    ref.onDispose(() => unawaited(statuses.cancel()));
    // A session started offline is reconnecting from the start.
    return session.status is Reconnecting;
  }
}

/// Whether to tell the user the link is being restored: true once
/// [ReconnectingController] has stayed true for [networkSettle], so a blip
/// that heals sooner shows nothing; false as soon as the link is back.
@Riverpod(keepAlive: true)
class ReconnectingNotice extends _$ReconnectingNotice {
  @override
  bool build() {
    Timer? grace;
    void wait() => grace = Timer(networkSettle, () => state = true);
    ref
      ..listen(reconnectingControllerProvider, (_, down) {
        grace?.cancel();
        if (!down) {
          state = false;
        } else if (!state) {
          wait();
        }
      })
      ..onDispose(() => grace?.cancel());
    // Asked for while the link is already down, e.g. after an offline start.
    if (ref.read(reconnectingControllerProvider)) {
      wait();
    }
    return false;
  }
}
