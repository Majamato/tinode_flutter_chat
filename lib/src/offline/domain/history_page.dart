import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Messages of one chat, oldest first, from the cache or the server.
final class HistoryPage with ValueObject {
  const HistoryPage(this.messages, {required this.reachedStart});

  final List<DataMessage> messages;

  /// Nothing older exists: the chat is loaded from its first message.
  final bool reachedStart;

  @override
  List<Object?> get props => [messages, reachedStart];
}

/// What arrived in a chat since the newest cached message.
final class CatchUp with ValueObject {
  const CatchUp(this.messages, {required this.gap});

  /// The newest messages after the cached ones, oldest first.
  final List<DataMessage> messages;

  /// More arrived than one page holds: the messages between the cached
  /// ones and [messages] are not loaded, so the chat should start over
  /// from [messages] and page back from there.
  final bool gap;

  @override
  List<Object?> get props => [messages, gap];
}
