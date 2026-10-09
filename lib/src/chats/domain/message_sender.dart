import 'package:tinode_flutter_chat/src/chats/domain/chat_member.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Who sent a message in a group, as its bubble shows it: the name on the
/// first message of a run, the avatar beside the last.
final class MessageSender with ValueObject {
  const MessageSender({
    required this.userId,
    required this.showName,
    required this.showAvatar,
    this.name,
    this.initials = '',
    this.photo,
  });

  /// [member] is null while the sender is not known yet.
  factory MessageSender.of(
    String userId,
    ChatMember? member, {
    required bool showName,
    required bool showAvatar,
  }) => MessageSender(
    userId: userId,
    name: member?.name,
    initials: member?.initials ?? '',
    photo: member?.photo,
    showName: showName,
    showAvatar: showAvatar,
  );

  final String userId;

  /// Null when unknown: the bubble then says so.
  final String? name;
  final String initials;
  final AvatarImage? photo;

  /// The message starts a run of messages from this sender.
  final bool showName;

  /// The message ends a run.
  final bool showAvatar;

  /// See [colorIndexOf].
  int get colorIndex => colorIndexOf(userId);

  @override
  List<Object?> get props => [
    userId,
    name,
    initials,
    photo,
    showName,
    showAvatar,
  ];
}
