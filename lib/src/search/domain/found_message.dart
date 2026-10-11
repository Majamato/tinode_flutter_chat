import 'package:tinode_flutter_chat/src/search/domain/message_snippet.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A message that message search found in its chat's cache.
final class FoundMessage with ValueObject {
  const FoundMessage({
    required this.topic,
    required this.seq,
    required this.time,
    required this.snippet,
    this.from,
  });

  final String topic;
  final int seq;
  final DateTime time;

  /// The sender's user ID; absent in channels and for server messages.
  final String? from;
  final MessageSnippet snippet;

  @override
  List<Object?> get props => [topic, seq, time, from, snippet];
}
