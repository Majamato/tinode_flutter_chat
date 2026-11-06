import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/domain/initials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/presence_visibility.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One entry of the chat list, as the list tile shows it.
final class ChatSummary with ValueObject {
  const ChatSummary({
    required this.topic,
    required this.kind,
    required this.title,
    this.photo,
    this.lastMessageAt,
    this.lastSeq = 0,
    this.read = 0,
    this.uncountedSeqs = const {},
    this.canWrite = true,
    this.canDeleteForEveryone = false,
    this.isOwner = false,
    this.canManageMembers = false,
    this.online = false,
    this.lastSeen,
    this.presenceHidden = false,
    this.muted = false,
  });

  factory ChatSummary.fromSubscription(Subscription subscription) {
    final topic = subscription.topic!;
    final name = subscription.public?.name?.trim();
    final hidden = subscription.public?.hidesPresence ?? false;
    return ChatSummary(
      topic: topic,
      kind: TopicKind.of(topic),
      title: name == null || name.isEmpty ? topic : name,
      photo: AvatarImage.tryParse(subscription.public?.photo),
      lastMessageAt: subscription.lastMessageAt,
      lastSeq: subscription.lastSeq,
      read: subscription.read,
      canWrite: subscription.access?.mode.has(Permission.write) ?? true,
      canDeleteForEveryone:
          subscription.access?.mode.has(Permission.delete) ?? false,
      isOwner: subscription.access?.mode.has(Permission.owner) ?? false,
      canManageMembers:
          subscription.access?.mode.has(Permission.approve) ?? false,
      online: !hidden && subscription.online,
      lastSeen: hidden ? null : subscription.seen?.when,
      presenceHidden: hidden,
      muted: !(subscription.access?.want.has(Permission.presence) ?? true),
    );
  }

  final String topic;
  final TopicKind kind;

  /// The profile name, or the topic name when there is none.
  final String title;

  /// The profile photo, when it is sent inline.
  final AvatarImage? photo;
  final DateTime? lastMessageAt;
  final int lastSeq;

  /// Highest seq this user has read.
  final int read;

  /// The seqs known to be no unread message (see `uncountedBy`): they use
  /// up a seq, so [unread] leaves them out. A `pres msg` doesn't tell: one
  /// counts until the cache has it.
  final Set<int> uncountedSeqs;

  /// False for channel followers, who can only read.
  final bool canWrite;

  /// The user may delete messages for everyone (`D`), e.g. a group's
  /// owner. Others can delete only for themselves.
  final bool canDeleteForEveryone;

  /// The user owns the group (`O`): deleting it deletes it for everyone.
  final bool isOwner;

  /// The user may remove members (`A`), e.g. a group's owner.
  final bool canManageMembers;

  /// The other user of a direct chat is online. Live only: the cache keeps
  /// no presence. For a group it means someone is attached, which the chat
  /// doesn't show.
  final bool online;

  /// When the other user of a direct chat was last online, if the server
  /// said or this device saw them go.
  final DateTime? lastSeen;

  /// The other user asked not to be shown online or with a last seen (see
  /// `PresenceVisibility`): [online] stays false and [lastSeen] null.
  final bool presenceHidden;

  /// The user turned off notifications for the chat: its `want` lacks
  /// presence (`P`), so the server sends no push for it.
  final bool muted;

  int get unread => lastSeq > read
      ? lastSeq -
            read -
            uncountedSeqs.where((seq) => seq > read && seq <= lastSeq).length
      : 0;

  /// Up to two letters for the avatar; see [initialsOf].
  String get initials => initialsOf(title);

  /// A new message [seq] arrived at [time]. Older news changes nothing.
  ChatSummary withMessage(int seq, DateTime time) => seq <= lastSeq
      ? this
      : _copy(
          lastSeq: seq,
          lastMessageAt: lastMessageAt == null || time.isAfter(lastMessageAt!)
              ? time
              : lastMessageAt,
        );

  /// [seqs] are no unread messages; see [uncountedSeqs].
  ChatSummary withUncounted(Set<int> seqs) => _copy(uncountedSeqs: seqs);

  /// The user read up to [seq]. A read marker never moves back.
  ChatSummary withRead(int seq) => seq <= read ? this : _copy(read: seq);

  /// The chat came online or went offline (`pres on` / `off`), the peer
  /// last seen at [lastSeen] when given.
  ChatSummary withOnline({required bool online, DateTime? lastSeen}) {
    if (presenceHidden) {
      return this;
    }
    final updated = online == this.online ? this : _copy(online: online);
    return lastSeen == null ? updated : updated.withLastSeen(lastSeen);
  }

  /// The peer was last seen at [time]. Last seen never moves back.
  ChatSummary withLastSeen(DateTime time) =>
      presenceHidden || (lastSeen != null && !time.isAfter(lastSeen!))
      ? this
      : _copy(lastSeen: time);

  ChatSummary _copy({
    int? lastSeq,
    DateTime? lastMessageAt,
    int? read,
    Set<int>? uncountedSeqs,
    bool? online,
    DateTime? lastSeen,
  }) => ChatSummary(
    topic: topic,
    kind: kind,
    title: title,
    photo: photo,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    lastSeq: lastSeq ?? this.lastSeq,
    read: read ?? this.read,
    uncountedSeqs: uncountedSeqs ?? this.uncountedSeqs,
    canWrite: canWrite,
    canDeleteForEveryone: canDeleteForEveryone,
    isOwner: isOwner,
    canManageMembers: canManageMembers,
    online: online ?? this.online,
    lastSeen: lastSeen ?? this.lastSeen,
    presenceHidden: presenceHidden,
    muted: muted,
  );

  @override
  List<Object?> get props => [
    topic,
    kind,
    title,
    photo,
    lastMessageAt,
    lastSeq,
    read,
    uncountedSeqs,
    canWrite,
    canDeleteForEveryone,
    isOwner,
    canManageMembers,
    online,
    lastSeen,
    presenceHidden,
    muted,
  ];
}
