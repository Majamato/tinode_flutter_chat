import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/history_page.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// A logged-in [TinodeSession] with a local cache: what the chats see.
///
/// It keeps what arrives in the cache, serves the chat list and history
/// from there first, and holds what the user does offline in an outbox
/// that is sent once the link is back.
abstract interface class ChatSession implements TinodeSession {
  /// The logged-in user, known even before the server answers.
  String get userId;

  /// The cached chat list, without asking the server. [chatList] syncs it
  /// with the server and returns the result.
  Future<List<Subscription>> storedChatList();

  /// The newest cached messages of [topic], without asking the server.
  Future<HistoryPage> storedPage(String topic, {required int limit});

  /// Up to [limit] messages before [before]: from the cache where it has
  /// them, from the server for the gaps. Offline, only what is cached.
  Future<HistoryPage> olderPage(
    String topic, {
    required int before,
    required int limit,
  });

  /// Fetches what arrived after the newest cached message and the
  /// deletions missed meanwhile. The topic must be attached.
  Future<CatchUp> catchUp(String topic, {required int limit});

  /// The messages of [topic] still in the outbox, oldest first.
  Future<List<OutgoingMessage>> storedOutgoing(String topic);

  /// Queues [content] and sends it as soon as the link allows.
  Future<OutgoingMessage> send(String topic, MessageContent content);

  /// Queues a failed message again.
  Future<void> retry(String clientId);

  /// Drops a queued or failed message. Throws [StateError] while it is on
  /// its way to the server.
  Future<void> discard(String clientId);

  /// Deletes messages now in the cache, and on the server once the link
  /// allows: for this user, or with [forEveryone] for all.
  Future<void> delete(
    String topic,
    List<SeqRange> ranges, {
    required bool forEveryone,
  });

  /// Changes of the outbox, for the chats that show it.
  Stream<OutboxEvent> get outbox;

  /// Messages deleted here, on another device or by others.
  Stream<TopicDeletion> get deletions;
}
