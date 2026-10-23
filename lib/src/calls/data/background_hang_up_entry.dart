import 'package:flutter_callkit_incoming/entities/entities.dart' as callkit;
import 'package:tinode_flutter_chat/src/calls/data/background_hang_up.dart';
import 'package:tinode_flutter_chat/src/calls/data/callkit_system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/domain/system_calls.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';

/// Tells the caller that the user declined a call on the system's screen
/// while the app was closed. Runs in a background isolate the plugin
/// starts; the call names the server and the token to hang up with.
@pragma('vm:entry-point')
Future<void> hangUpDeclined(callkit.CallEvent event) async {
  if (event case callkit.CallEventActionCallDecline(:final callKitParams)) {
    if (systemCallOf(callKitParams) case SystemCall(
      :final topic,
      :final seq,
      hangUpWith: final credentials?,
    )) {
      await hangUpFromBackground(
        ClientTinodeSession.connect,
        credentials,
        topic,
        seq,
      );
    }
  }
}
