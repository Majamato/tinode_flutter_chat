import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';

/// [SystemCalls] that do nothing: for desktops, which have no system call
/// screen, and for hosts that turn it off. Calls ring in the app only.
final class NoSystemCalls implements SystemCalls {
  const NoSystemCalls();

  @override
  Stream<SystemCallAction> get actions => const Stream.empty();

  @override
  Future<void> ring(SystemCall call, {required Duration ringFor}) async {}

  @override
  Future<void> placed(SystemCall call) async {}

  @override
  Future<void> acceptedInApp(SystemCall call) async {}

  @override
  Future<void> connected(String topic, int seq) async {}

  @override
  Future<void> end(String topic, int seq, {bool missed = false}) async {}

  @override
  Future<void> stopRinging(
    String topic,
    int seq, {
    bool missed = false,
  }) async {}

  @override
  Future<void> setMuted(String topic, int seq, {required bool muted}) async {}

  @override
  Future<List<SystemCall>> accepted() async => const [];
}
