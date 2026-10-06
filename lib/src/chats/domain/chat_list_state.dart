import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_summary.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// The chat list: every chat by topic, and the topics newest first.
///
/// Updates return `this` when nothing changed, and keep the same [order]
/// instance while the order is the same, so widgets that select [order]
/// do not rebuild when only a counter changed.
@immutable
final class ChatListState {
  const ChatListState.loading()
    : status = LoadStatus.loading,
      failure = null,
      byTopic = const {},
      order = const [];

  const ChatListState._(this.status, this.failure, this.byTopic, this.order);

  final LoadStatus status;

  /// Why the load failed; set when [status] is [LoadStatus.failed].
  final ChatFailure? failure;
  final Map<String, ChatSummary> byTopic;

  /// Topics by last message, newest first.
  final List<String> order;

  ChatListState loaded(Iterable<ChatSummary> chats) {
    final byTopic = {for (final chat in chats) chat.topic: chat};
    return ChatListState._(
      LoadStatus.ready,
      null,
      Map.unmodifiable(byTopic),
      _sorted(byTopic),
    );
  }

  ChatListState failed(ChatFailure failure) =>
      ChatListState._(LoadStatus.failed, failure, byTopic, order);

  bool contains(String topic) => byTopic.containsKey(topic);

  /// Applies [update] to the chat named [topic], if the list has it.
  ChatListState update(
    String topic,
    ChatSummary Function(ChatSummary chat) update,
  ) {
    final chat = byTopic[topic];
    if (chat == null) {
      return this;
    }

    final updated = update(chat);
    if (updated == chat) {
      return this;
    }
    final chats = Map.of(byTopic)..[topic] = updated;
    final newOrder = updated.lastMessageAt == chat.lastMessageAt
        ? order
        : _sorted(chats);

    return ChatListState._(
      status,
      failure,
      Map.unmodifiable(chats),
      const ListEquality<String>().equals(newOrder, order) ? order : newOrder,
    );
  }

  static List<String> _sorted(Map<String, ChatSummary> byTopic) =>
      List.unmodifiable(
        byTopic.values.sorted(_newestFirst).map((chat) => chat.topic),
      );

  static int _newestFirst(ChatSummary a, ChatSummary b) {
    final at = a.lastMessageAt;
    final bt = b.lastMessageAt;
    if (at == null || bt == null) {
      return at == bt ? a.topic.compareTo(b.topic) : (at == null ? 1 : -1);
    }
    final byTime = bt.compareTo(at);
    return byTime != 0 ? byTime : a.topic.compareTo(b.topic);
  }
}
