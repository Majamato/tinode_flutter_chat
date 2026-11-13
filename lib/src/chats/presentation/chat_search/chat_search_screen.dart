import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_search/chat_search_input.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_search/chat_search_results.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_field.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_back_button.dart';

/// The chat search: the user's own chats, direct and groups, filtered by
/// name as the user types, without the server. Tapping one opens it.
/// Watches nothing itself.
class ChatSearchScreen extends StatelessWidget {
  const ChatSearchScreen({super.key});

  /// Pushes the chat search over the chat list.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ChatSearchScreen()));

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      screen: TinodeChatSearchScreen(),
      appBar: TinodeAppBar(
        centerTitle: false,
        titleOnGlass: true,
        leading: TinodeBackButton(),
        title: GlassField(child: ChatSearchInput()),
      ),
      body: SafeArea(bottom: false, child: ChatSearchResults()),
    );
  }
}
