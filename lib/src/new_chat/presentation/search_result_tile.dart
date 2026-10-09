import 'package:flutter/material.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// One search result: photo or initials, name, whether it is a group, and, when
/// results are picked, a checkbox. Watches nothing.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.result,
    required this.onTap,
    this.selected,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onTap;

  /// Whether the result is picked; null when results are not picked.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final label = switch (result.kind) {
      TopicKind.group => strings.groupLabel,
      TopicKind.channel => strings.channelLabel,
      _ => null,
    };
    final selected = this.selected;
    return ListTile(
      leading: ProfileAvatar(initials: result.initials, photo: result.photo),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: label == null ? null : Text(label),
      trailing: selected == null
          ? null
          : Checkbox(value: selected, onChanged: (_) => onTap()),
      onTap: onTap,
    );
  }
}
