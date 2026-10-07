import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

part 'background_policy.g.dart';

/// How long the socket stays open after the app leaves the screen. Push
/// notifications cover the time after that, and the battery is spared.
const backgroundGrace = Duration(seconds: 15);

/// Suspends the session a while after the app is hidden and resumes it
/// when the app is shown again. During a call the session stays open: the
/// grace starts when the call ends.
@Riverpod(keepAlive: true)
class BackgroundPolicy extends _$BackgroundPolicy {
  Timer? _suspend;
  var _hidden = false;
  var _inCall = false;

  @override
  void build() => ref.onDispose(() => _suspend?.cancel());

  void hidden() {
    _hidden = true;
    _suspend?.cancel();
    _suspend = _inCall ? null : Timer(backgroundGrace, _suspendNow);
  }

  /// Resuming also probes a socket that stayed open but may have died.
  void shown() {
    _hidden = false;
    _suspend?.cancel();
    _suspend = null;
    _session?.resume();
  }

  /// Whether a call is running, which keeps the session open.
  void keepOpen({required bool inCall}) {
    if (inCall == _inCall) {
      return;
    }
    _inCall = inCall;
    _suspend?.cancel();
    _suspend = !inCall && _hidden ? Timer(backgroundGrace, _suspendNow) : null;
  }

  void _suspendNow() => _session?.suspend();

  TinodeSession? get _session =>
      ref.read(sessionControllerProvider).value?.session;
}
