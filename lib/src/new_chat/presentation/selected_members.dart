import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';

/// The people picked for a new group, as chips that remove them. Watches
/// nothing.
class SelectedMembers extends StatelessWidget {
  const SelectedMembers({
    required this.members,
    required this.onRemove,
    super.key,
  });

  final List<SearchResult> members;
  final ValueChanged<SearchResult> onRemove;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final member in members)
            Padding(
              key: ValueKey(member.topic),
              padding: const EdgeInsets.only(right: 8),
              child: InputChip(
                avatar: CircleAvatar(child: Text(member.initials)),
                label: Text(member.title),
                onDeleted: () => onRemove(member),
              ),
            ),
        ],
      ),
    );
  }
}
