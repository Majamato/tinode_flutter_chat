import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/domain/initials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A user or group that a search found, as its tile shows it.
final class SearchResult with ValueObject {
  const SearchResult({
    required this.topic,
    required this.kind,
    required this.title,
    this.photo,
    this.memberCount,
  });

  factory SearchResult.fromFound(FoundTopic found) {
    final name = found.public?.name?.trim();
    return SearchResult(
      topic: found.topic,
      kind: found.kind,
      title: name == null || name.isEmpty ? found.topic : name,
      photo: AvatarImage.tryParse(found.public?.photo),
      memberCount: found.memberCount,
    );
  }

  /// A user's ID, which also names the 1:1 chat with them, or a group's
  /// name.
  final String topic;
  final TopicKind kind;

  /// The profile name, or [topic] when there is none.
  final String title;

  /// The profile photo, when it is sent inline.
  final AvatarImage? photo;

  /// Members of a group; null for users.
  final int? memberCount;

  bool get isUser => kind == TopicKind.direct;

  /// Up to two letters for the avatar; see [initialsOf].
  String get initials => initialsOf(title);

  @override
  List<Object?> get props => [topic, kind, title, photo, memberCount];
}
