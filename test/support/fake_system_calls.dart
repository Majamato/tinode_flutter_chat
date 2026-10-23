import 'dart:async';

import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';

/// Scripted [SystemCalls]: it records every report in [log], and tests act
/// on the system's screen with [emit]. [acceptedCalls] are the calls
/// [accepted] returns, e.g. accepted before the app started.
final class FakeSystemCalls implements SystemCalls {
  /// Every report, e.g. `ring usrBob 1 video Bob 30s` or `end usrBob 1`.
  final log = <String>[];

  /// The calls rung or placed, last one last.
  final reported = <SystemCall>[];

  /// What [accepted] returns.
  final acceptedCalls = <SystemCall>[];

  /// Calls still ringing here, as `topic seq`; [stopRinging] ends only
  /// these.
  final ringing = <String>{};

  final _actions = StreamController<SystemCallAction>.broadcast(sync: true);

  void emit(SystemCallAction action) => _actions.add(action);

  @override
  Stream<SystemCallAction> get actions => _actions.stream;

  @override
  Future<void> ring(SystemCall call, {required Duration ringFor}) async {
    reported.add(call);
    ringing.add('${call.topic} ${call.seq}');
    log.add(
      'ring ${call.topic} ${call.seq} ${call.audioOnly ? 'audio' : 'video'} '
      '${call.callerName} ${ringFor.inSeconds}s',
    );
  }

  @override
  Future<void> placed(SystemCall call) async {
    reported.add(call);
    log.add('placed ${call.topic} ${call.seq} ${call.callerName}');
  }

  @override
  Future<void> acceptedInApp(SystemCall call) async {
    ringing.remove('${call.topic} ${call.seq}');
    log.add('acceptedInApp ${call.topic} ${call.seq}');
  }

  @override
  Future<void> connected(String topic, int seq) async =>
      log.add('connected $topic $seq');

  @override
  Future<void> end(String topic, int seq, {bool missed = false}) async {
    ringing.remove('$topic $seq');
    log.add('end $topic $seq${missed ? ' missed' : ''}');
  }

  @override
  Future<void> stopRinging(String topic, int seq, {bool missed = false}) async {
    if (ringing.remove('$topic $seq')) {
      log.add('stopRinging $topic $seq${missed ? ' missed' : ''}');
    }
  }

  @override
  Future<void> setMuted(String topic, int seq, {required bool muted}) async =>
      log.add('muted $topic $seq $muted');

  @override
  Future<List<SystemCall>> accepted() async => List.of(acceptedCalls);
}
