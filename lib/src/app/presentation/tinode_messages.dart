import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/app/presentation/isolate_port_names.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/push/application/message_push_handler.dart';
import 'package:tinode_flutter_chat/src/push/domain/tinode_push_names.dart';
import 'package:tinode_flutter_chat/src/session/data/client_tinode_session.dart';

/// New messages announced by push while the app is in the background or
/// closed: fetched into the chats kept on the device and marked received,
/// so the sender sees them delivered and the chat shows them even offline.
///
/// Hand every push from the background handler of your push service to
/// [handlePush], after `TinodeCalls.handlePush`. Name the notification
/// with [cachedNames] to show it at once, then with what [handlePush]
/// returns, which may know more, e.g. a chat new to the device:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> onBackgroundPush(RemoteMessage message) async {
///   final push = TinodePush.tryParse(message.data);
///   if (push == null) return;
///   final token = await readToken();
///   if (await TinodeCalls.handlePush(push, config: config, token: token)) {
///     return;
///   }
///   final shown = push is MessagePush && !push.silent;
///   final cached = await TinodeMessages.cachedNames(push, config: config);
///   if (shown) await showNotification(push, cached);
///   final names = await TinodeMessages.handlePush(
///     push,
///     config: config,
///     token: token,
///   );
///   if (shown && names != null && names != cached) {
///     await showNotification(push, names, quietly: true);
///   }
/// }
/// ```
abstract final class TinodeMessages {
  /// Fetches what [push] announces for the user who last logged in to
  /// [config]'s server, with their saved [token]:
  ///
  /// - a new message: the chat's new messages and its delete log, then the
  ///   received marker, sent while the chat is attached;
  /// - a read marker (`ReadPush`): kept, with no connection;
  /// - a new chat (`SubscriptionPush`): that chat, with its name.
  ///
  /// While the app lives in this process, its own session does it, waking
  /// for a moment if it was suspended; otherwise this logs in for the
  /// fetch and leaves. A message the device marked received already needs
  /// no connection. It never sends what the user wrote offline: the app
  /// does when it opens. Best effort, within 15 seconds: a failure leaves
  /// the catching up to the app.
  ///
  /// Returns the names the notification can show, from the chats kept on
  /// the device; null when it doesn't handle [push] (a call: see
  /// `TinodeCalls`), with no [token], or with no user on the device.
  static Future<TinodePushNames?> handlePush(
    TinodePush push, {
    required TinodeConfig config,
    required String? token,
  }) => handleMessagePush(
    push,
    config: config,
    token: token,
    storeOpener: const DeviceChatStoreOpener(),
    connect: ClientTinodeSession.connect,
    portNames: const IsolatePortNames(),
  );

  /// The names the chats kept on the device give a notification of [push],
  /// for the user who last logged in to [config]'s server: read at once,
  /// without the server, so the notification can show before [handlePush]
  /// is done. Null with no user on the device, or when the chats can't be
  /// read within 2 seconds.
  static Future<TinodePushNames?> cachedNames(
    TinodePush push, {
    required TinodeConfig config,
  }) => cachedPushNames(
    push,
    server: config.server,
    storeOpener: const DeviceChatStoreOpener(),
  );
}
