import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';

part 'network_policy.g.dart';

/// How long network reports must stay quiet before acting on them: iOS
/// can report `none` and then `wifi` within moments.
const networkSettle = Duration(seconds: 1);

/// The probe deadline after a network change, which makes a dead socket
/// likely; the idle probe keeps the client's longer default.
const networkProbeTimeout = Duration(seconds: 4);

/// Turns the OS's network changes into checks of the link. Only a hint:
/// the socket's own status decides what the user sees.
@Riverpod(keepAlive: true)
class NetworkPolicy extends _$NetworkPolicy {
  @override
  void build() {
    Timer? settle;
    final changes = ref.watch(networkMonitorProvider).changes.listen(
      (available) {
        settle?.cancel();
        settle = Timer(networkSettle, () => _check(available: available));
      },
      // A broken hint source must never break the chat.
      onError: (Object _) {},
    );
    ref.onDispose(() {
      settle?.cancel();
      unawaited(changes.cancel());
    });
  }

  void _check({required bool available}) {
    final session = ref.read(sessionControllerProvider).value?.session;
    if (session == null) {
      return;
    }
    switch (session.status) {
      case Connected():
        session.resume(probeTimeout: networkProbeTimeout);
      case Reconnecting() when available:
        session.resume();
      case _:
      // Suspended in the background or closed for good: not ours to wake.
    }
  }
}
