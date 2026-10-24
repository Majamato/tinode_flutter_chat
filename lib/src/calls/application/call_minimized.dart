import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/domain/active_call.dart';

part 'call_minimized.g.dart';

/// Whether the user minimized the running call to the call bar, to use the
/// chats meanwhile. Each call starts full screen, and a ringing call always
/// shows full screen; an ended call stays where it was until it goes.
@Riverpod(keepAlive: true)
class CallMinimized extends _$CallMinimized {
  @override
  bool build() {
    ref.listen(callControllerProvider, (previous, call) {
      final begins = call != null && !call.isOver && (previous?.isOver ?? true);
      if (call == null || call.stage == CallStage.incoming || begins) {
        state = false;
      }
    });
    return false;
  }

  void minimize() {
    if (ref.read(callControllerProvider) case final call?
        when call.stage != CallStage.incoming) {
      state = true;
    }
  }

  void expand() => state = false;
}
