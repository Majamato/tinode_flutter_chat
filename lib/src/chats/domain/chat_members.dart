import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/chats/domain/message_receipt.dart';

/// The members of one chat, by user ID: who sent what, and how far each
/// read and received.
///
/// Updates return `this` when nothing changed, so a provider holding it
/// stays quiet.
@immutable
final class ChatMembers {
  const ChatMembers([this.byId = const {}]);

  final Map<String, ChatMember> byId;

  ChatMember? operator [](String? userId) => byId[userId];

  /// The members from a full `get sub`: whoever it leaves out is no longer
  /// a member.
  ChatMembers withMembers(Iterable<Subscription> subscriptions) {
    final members = {
      for (final s in subscriptions.where((s) => s.userId != null))
        s.userId!: ChatMember.fromSubscription(s, previous: byId[s.userId]),
    };
    return const MapEquality<String, ChatMember>().equals(members, byId)
        ? this
        : ChatMembers(Map.unmodifiable(members));
  }

  /// One member, joined or read again.
  ChatMembers withMember(Subscription subscription) {
    final id = subscription.userId!;
    return _with(ChatMember.fromSubscription(subscription, previous: byId[id]));
  }

  /// [userId] left, or was removed.
  ChatMembers without(String userId) => byId.containsKey(userId)
      ? ChatMembers(Map.unmodifiable(Map.of(byId)..remove(userId)))
      : this;

  /// [userId] read or received more, e.g. from an `info`. Unknown users
  /// change nothing.
  ChatMembers advanced(String userId, {int? read, int? received}) {
    final member = byId[userId];
    return member == null
        ? this
        : _with(member.advanced(read: read, received: received));
  }

  /// How far the user [me]'s message [seq] got: read or delivered once
  /// every other member who may read has. In a channel, whose followers
  /// stay anonymous, and while nobody else is known, it is just sent.
  MessageReceipt receiptOf(
    int seq, {
    required String me,
    required TopicKind kind,
  }) {
    if (kind == TopicKind.channel) {
      return MessageReceipt.sent;
    }
    final others = _readersBesides(me);
    if (others.isEmpty) {
      return MessageReceipt.sent;
    }
    if (others.every((m) => m.hasRead(seq))) {
      return MessageReceipt.read;
    }
    if (others.every((m) => m.hasReceived(seq))) {
      return MessageReceipt.delivered;
    }
    return MessageReceipt.sent;
  }

  /// The other members who read message [seq], and those who only
  /// received it, each by name.
  ({List<ChatMember> read, List<ChatMember> delivered}) readBy(
    int seq, {
    required String me,
  }) {
    final others = _readersBesides(me).sorted(_byName);
    return (
      read: [
        for (final m in others)
          if (m.hasRead(seq)) m,
      ],
      delivered: [
        for (final m in others)
          if (!m.hasRead(seq) && m.hasReceived(seq)) m,
      ],
    );
  }

  Iterable<ChatMember> _readersBesides(String me) =>
      byId.values.where((m) => m.userId != me && m.canRead);

  ChatMembers _with(ChatMember member) => byId[member.userId] == member
      ? this
      : ChatMembers(Map.unmodifiable({...byId, member.userId: member}));

  static int _byName(ChatMember a, ChatMember b) => (a.name ?? a.userId)
      .toLowerCase()
      .compareTo((b.name ?? b.userId).toLowerCase());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMembers &&
          const MapEquality<String, ChatMember>().equals(other.byId, byId);

  @override
  int get hashCode => const MapEquality<String, ChatMember>().hash(byId);
}
