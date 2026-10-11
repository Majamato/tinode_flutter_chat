import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// How much of each user's chats `TinodeChat` keeps on the device.
///
/// The cache is pruned once each time a user's chats open: each chat keeps
/// its newest [messagesPerChat] messages, and the downloaded files used
/// longest ago go until the rest fit in [fileCacheBytes]. Pruned messages
/// load from the server again when the user scrolls back to them, and
/// pruned files when they are shown or opened.
///
/// Message search runs over the cache, so it finds only the messages kept:
/// raise [messagesPerChat] to search further back.
final class TinodeCacheLimits with ValueObject {
  /// Creates the limits; by default 1000 messages per chat and 200 MiB of
  /// files.
  const TinodeCacheLimits({
    this.messagesPerChat = 1000,
    this.fileCacheBytes = 200 * 1024 * 1024,
  }) : assert(messagesPerChat > 0, 'keep at least one message per chat'),
       assert(fileCacheBytes >= 0, 'a size is never negative');

  /// How many of each chat's newest messages stay on the device.
  final int messagesPerChat;

  /// How many bytes of downloaded and sent files stay on the device. Files
  /// waiting to be sent don't count and are always kept.
  final int fileCacheBytes;

  @override
  List<Object?> get props => [messagesPerChat, fileCacheBytes];
}
