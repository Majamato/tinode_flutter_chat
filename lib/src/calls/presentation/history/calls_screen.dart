import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_body.dart';
import 'package:tinode_flutter_chat/src/session/presentation/reconnecting_title.dart';
import 'package:tinode_flutter_chat/src/shared/domain/tinode_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_scaffold.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/tinode_app_bar.dart';

/// The calls tab: the calls of the direct chats, newest first, scrolling
/// under the glass app bar, whose title shows when the link is being
/// restored. Each time it shows (its tab is picked, or a
/// screen over it closes) it fetches the chats the cache is behind on.
/// Watches nothing.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  var _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shown = TickerMode.of(context);
    if (shown && !_shown) {
      unawaited(ref.read(callHistoryControllerProvider.notifier).refresh());
    }
    _shown = shown;
  }

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
