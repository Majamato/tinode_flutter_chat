import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_body.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_title.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The calls tab: the calls of the direct chats, newest first, scrolling
/// under the glass app bar, whose title shows when the link is being
/// restored. Watches nothing.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      screen: const TinodeCallsScreen(),
      appBar: TinodeAppBar(
        title: ReconnectingTitle(
          title: Text(TinodeChatStrings.of(context).callsTitle),
        ),
      ),
      body: const CallHistoryBody(),
    );
  }
}
