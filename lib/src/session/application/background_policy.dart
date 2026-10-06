import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

part 'background_policy.g.dart';

/// How long the socket stays open after the app leaves the screen. Push
/// notifications cover the time after that, and the battery is spared.
const backgroundGrace = Duration(seconds: 15);

/// Suspends the session a while after the app is hidden and resumes it
/// when the app is shown again.
@Riverpod(keepAlive: true)
class BackgroundPolicy extends _$BackgroundPolicy {
  Timer? _suspend;

  @override
  void build() => ref.onDispose(() => _suspend?.cancel());

  void hidden() {
    _suspend?.cancel();
    _suspend = Timer(backgroundGrace, () => _session?.suspend());
  }

  /// Resuming also probes a socket that stayed open but may have died.
  void shown() {
    _suspend?.cancel();
    _suspend = null;
    _session?.resume();
  }

  TinodeSession? get _session =>
      ref.read(sessionControllerProvider).value?.session;
}
