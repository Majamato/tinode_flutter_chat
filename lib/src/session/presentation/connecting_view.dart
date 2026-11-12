import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_list_skeleton.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_search_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// Shown while the session connects (and logs in with known credentials):
/// the chat list's skeleton, under a bar saying "Connecting…" with the
/// search field's bone and nothing to tap. The host's `appBarBuilder` isn't
/// asked, as nothing can open yet.
class ConnectingView extends StatelessWidget {
  const ConnectingView({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: null,
      appBar: TinodeAppBar(
        title: Semantics(
          liveRegion: true,
          child: Text(TinodeChatStrings.of(context).connecting),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(ChatSearchField.height),
          child: SkeletonBone.line(height: ChatSearchField.height),
        ),
      ),
      body: const ChatListSkeleton(),
    );
  }
}
