import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// How a found message's result names its sender.
enum FoundSenderKind {
  /// The user.
  own,

  /// Named by the chat's title: the peer of a direct chat, or a channel.
  chat,

  /// A member of a group, by [FoundSender.name].
  member,
}

/// Who sent a found message, as its result names them.
final class FoundSender with ValueObject {
  const FoundSender.own() : kind = FoundSenderKind.own, name = null;
  const FoundSender.chat() : kind = FoundSenderKind.chat, name = null;

  /// A group member; [name] is null while unknown.
  const FoundSender.member(this.name) : kind = FoundSenderKind.member;

  final FoundSenderKind kind;
  final String? name;

  @override
  List<Object?> get props => [kind, name];
}
