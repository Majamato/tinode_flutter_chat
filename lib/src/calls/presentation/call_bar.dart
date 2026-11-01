import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_minimized.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_status_text.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// [child], the chats, under a bar for the minimized call: who is on the
/// call and for how long. A tap on the bar brings the call back. While it
/// shows, it takes the status bar's space from [child]. Watches only
/// whether the call is minimized.
class CallBar extends ConsumerWidget {
  const CallBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(callMinimizedProvider);
    // The same children either way, so the chats keep their state.
    return Column(
      children: [
        if (shown) const _Bar() else const SizedBox.shrink(),
        Expanded(
          // Its own container, so a route's barrier in [child] doesn't
          // hide the bar from screen readers.
          child: Semantics(
            container: true,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: shown,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// The bar itself; watches the call's topic and whether it has video.
class _Bar extends ConsumerWidget {
  const _Bar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final call = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : (topic: c.topic, video: !c.audioOnly),
      ),
    );
    if (call == null) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colors.onPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    return Semantics(
      button: true,
      label: TinodeChatStrings.of(context).returnToCall,
      child: Material(
        color: colors.primary,
        child: InkWell(
          onTap: () => ref.read(callMinimizedProvider.notifier).expand(),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DefaultTextStyle.merge(
                  style: style,
                  child: Row(
                    children: [
                      Icon(
                        call.video ? icons.videoCall : icons.voiceCall,
                        size: 18,
                        color: colors.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: ChatTitle(topic: call.topic)),
                      Text(' · ', style: style),
                      CallStatusText(textAlign: TextAlign.start, style: style),
                      const Spacer(),
                      Icon(icons.restoreCall, color: colors.onPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
