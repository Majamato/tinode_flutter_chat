import 'package:meta/meta.dart';

/// What a notification for a push can name, as the chats kept on the device
/// have it: the [chat], and in a group the [sender] of the message. Either
/// is null when the device doesn't know it.
@immutable
final class TinodePushNames {
  const TinodePushNames({this.chat, this.sender});

  final String? chat;
  final String? sender;

  @override
  bool operator ==(Object other) =>
      other is TinodePushNames && other.chat == chat && other.sender == sender;

  @override
  int get hashCode => Object.hash(chat, sender);

  @override
  String toString() => 'TinodePushNames(chat: $chat, sender: $sender)';
}
