import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/active_session.dart';

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
