import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_history_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/history/call_history_body.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/frosted_header.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/size_reporter.dart';

/// The calls tab: the calls of the direct chats, newest first, under a
/// frosted header. Each time it shows (its tab is picked, or a screen over
/// it closes) it fetches the chats the cache is behind on. Watches
/// nothing.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  final _headerHeight = ValueNotifier<double>(0);
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
  void dispose() {
    _headerHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CallHistoryBody(topInset: _headerHeight)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizeReporter(
              height: _headerHeight,
              child: FrostedHeader(
                title: TinodeChatStrings.of(context).callsTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
