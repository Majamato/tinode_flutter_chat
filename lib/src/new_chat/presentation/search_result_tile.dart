import 'package:flutter/material.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/search_result.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';

/// One search result: photo or initials, name, and whether it is a group.
/// Watches nothing.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.result,
    required this.onTap,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final label = switch (result.kind) {
      TopicKind.group => strings.groupLabel,
      TopicKind.channel => strings.channelLabel,
      _ => null,
    };
    return ListTile(
      leading: ProfileAvatar(initials: result.initials, photo: result.photo),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: label == null ? null : Text(label),
      onTap: onTap,
    );
  }
}
