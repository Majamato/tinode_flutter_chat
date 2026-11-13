import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The people picked for a new group, in the order picked.
final class PickedMembers with ValueObject {
  const PickedMembers([this.members = const []]);

  final List<SearchResult> members;

  int get count => members.length;

  bool get isEmpty => members.isEmpty;

  /// Whether the person named [topic] is picked.
  bool has(String topic) => members.any((m) => m.topic == topic);

  /// Picks [member], or unpicks them when picked.
  PickedMembers toggled(SearchResult member) => PickedMembers(
    List.unmodifiable(
      has(member.topic)
          ? members.where((m) => m.topic != member.topic)
          : [...members, member],
    ),
  );

  @override
  List<Object?> get props => [members];
}
