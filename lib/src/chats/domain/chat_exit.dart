import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';

/// How the user gets rid of a chat.
enum ChatExit {
  /// Deletes a 1:1 chat for the user; the peer keeps their side.
  deleteChat,

  /// Deletes a group the user owns, for everyone.
  deleteGroup,

  /// Leaves a group someone else owns, on every device.
  leaveGroup;

  static ChatExit of(ChatSummary chat) => switch (chat.kind) {
    TopicKind.group ||
    TopicKind.channel => chat.isOwner ? deleteGroup : leaveGroup,
    _ => deleteChat,
  };
}
