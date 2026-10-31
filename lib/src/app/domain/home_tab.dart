import 'package:tinode_flutter_chat/src/session/domain/tinode_chat_features.dart';

/// A tab of the chat's tab bar.
enum HomeTab {
  chats,
  calls,
  settings;

  /// The tabs [features] offer: the calls history only with some kind of
  /// call.
  static List<HomeTab> offeredBy(TinodeChatFeatures features) => [
    chats,
    if (features.voiceCalls || features.videoCalls) calls,
    settings,
  ];
}
