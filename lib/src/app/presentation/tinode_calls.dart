import 'dart:ui';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_push_handler.dart';
import 'package:tinode_flutter_chat/src/calls/data/background_hang_up.dart';
import 'package:tinode_flutter_chat/src/calls/data/callkit_system_calls.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/system_call_texts_of.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Calls that ring while the app is in the background or closed, on the
/// phone's own call screens: CallKit on iOS, a self-managed Telecom
/// connection on Android.
///
/// Hand every push from the background handler of your push service to
/// [handlePush] first:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> onBackgroundPush(RemoteMessage message) async {
///   final push = TinodePush.tryParse(message.data);
///   if (push == null) return;
///   final token = (await SharedPreferences.getInstance()).getString('token');
///   if (await TinodeCalls.handlePush(push, config: config, token: token)) {
///     return;
///   }
///   if (!push.silent) showNotification(push);
/// }
/// ```
///
/// While the app is open, `TinodeChat` rings by itself: leave call pushes
/// that arrive then alone.
abstract final class TinodeCalls {
  /// Rings for [push] when it starts a call to the user, and stops the
  /// ringing when it says the call was taken on another device or is over.
  /// Accepting opens the app straight into the call.
  ///
  /// [config] is the one given to `TinodeChat`: the caller's name comes
  /// from the chats kept on the device for the user who last logged in to
  /// its server. With [token], the user's saved token, a call declined
  /// while the app is closed is hung up for the caller at once; the token
  /// stays with the ringing call until it ends. Without it, the caller
  /// hears it ring until the server gives up. Pass the [features] given to
  /// `TinodeChat`: a call of a kind they turn off doesn't ring. The ringing
  /// screen shows [strings], by default the built-in ones of the phone's
  /// locale.
  ///
  /// Returns whether [push] was about a call. Call pushes are all
  /// `silent`, so there is nothing more to show for them.
  static Future<bool> handlePush(
    TinodePush push, {
    required TinodeConfig config,
    String? token,
    TinodeChatStrings? strings,
    TinodeChatFeatures features = const TinodeChatFeatures(),
  }) => handleCallPush(
    push,
    config: config,
    token: token,
    features: features,
    systemCalls: deviceSystemCalls(
      systemCallTextsOf(
        strings ??
            TinodeChatStrings.forLocale(PlatformDispatcher.instance.locale),
      ),
    ),
    storeOpener: DeviceChatStoreOpener(),
    registerHangUp: registerBackgroundHangUp,
  );

  /// Asks for what the ringing screen needs on Android: notifications
  /// (Android 13+), and on Android 14+ full screen notifications, which
  /// opens the system's settings when not yet allowed. Does nothing on
  /// iOS. Call it at a moment the user expects it, e.g. after logging in.
  static Future<void> requestPermissions() => CallKitSystemCalls.supported
      ? CallKitSystemCalls.requestPermissions()
      : Future.value();
}
