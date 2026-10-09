import 'dart:math';

import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/domain/initials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// One member of a chat: who they are, for sender labels, and how far they
/// read and received, for receipts.
final class ChatMember with ValueObject {
  const ChatMember({
    required this.userId,
    this.name,
    this.photo,
    this.read = 0,
    this.received = 0,
    this.canRead = true,
  });

  /// [subscription] is a member entry of `get sub`. A `public` it leaves
  /// out keeps [previous]'s name and photo, and counters never move back.
  factory ChatMember.fromSubscription(
    Subscription subscription, {
    ChatMember? previous,
  }) {
    final public = subscription.public;
    final name = public?.name?.trim();
    return ChatMember(
      userId: subscription.userId!,
      name: public == null
          ? previous?.name
          : (name == null || name.isEmpty ? null : name),
      photo: public == null
          ? previous?.photo
          : AvatarImage.tryParse(public.photo),
      read: max(subscription.read, previous?.read ?? 0),
      received: max(subscription.received, previous?.received ?? 0),
      canRead: subscription.access?.mode.has(Permission.read) ?? true,
    );
  }

  final String userId;

  /// The profile name; null when the member has none, e.g. in a direct
  /// chat, where the server sends no profiles.
  final String? name;
  final AvatarImage? photo;

  /// The highest seq the member read, and received.
  final int read;
  final int received;

  /// The member may read messages (`R`): only such members count for
  /// receipts.
  final bool canRead;

  /// Up to two letters for the avatar; empty without a [name].
  String get initials => initialsOf(name ?? '');

  /// See [colorIndexOf].
  int get colorIndex => colorIndexOf(userId);

  bool hasRead(int seq) => read >= seq;

  /// Reading implies receiving, though the server keeps them apart.
  bool hasReceived(int seq) => read >= seq || received >= seq;

  /// This member with counters raised to [read] and [received]; they never
  /// move back.
  ChatMember advanced({int? read, int? received}) {
    final newRead = max(this.read, read ?? 0);
    final newReceived = max(this.received, received ?? 0);
    if (newRead == this.read && newReceived == this.received) {
      return this;
    }
    return ChatMember(
      userId: userId,
      name: name,
      photo: photo,
      read: newRead,
      received: newReceived,
      canRead: canRead,
    );
  }

  @override
  List<Object?> get props => [userId, name, photo, read, received, canRead];
}

/// The same number for the same user on every device, to pick their
/// colour from a palette.
int colorIndexOf(String userId) {
  // FNV-1a, 32 bits.
  var hash = 0x811c9dc5;
  for (final unit in userId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}
