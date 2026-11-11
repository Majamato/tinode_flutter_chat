import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/message_runs.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_presence_line.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/typing_indicator.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The line under the chat's title: a small spinner and "Reconnecting…" in
/// `outline` while the link is being restored (typing and presence are
/// stale meanwhile), else who is typing, else the [ChatPresenceLine]. A
/// new line fades in rising a little over the old one, and the height
/// eases as a line comes or goes, so the title glides; with Reduce motion
/// it only fades.
class ChatStatus extends ConsumerWidget {
  const ChatStatus({required this.topic, super.key});

  /// How far a new line rises as it fades in, as a share of its height.
  static const _rise = 0.25;

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = TinodeChatTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final Widget line = AnimatedSwitcher(
      duration: theme.fadeDuration,
      layoutBuilder: _layout,
      transitionBuilder: still ? _fade : _fadeAndRise,
      child: _line(ref),
    );
    // AnimatedSize can't run with no duration, so Reduce motion skips it.
    if (still) {
      return line;
    }
    return AnimatedSize(
      duration: theme.springDuration,
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.topStart,
      child: line,
    );
  }

  Widget _line(WidgetRef ref) {
    if (ref.watch(reconnectingNoticeProvider)) {
      return const _Reconnecting();
    }
    if (ref.watch(anyoneTypingProvider(topic))) {
      return TypingIndicator(topic: topic);
    }
    return ChatPresenceLine(topic: topic);
  }

  /// The old line and the new, at the start edge.
  static Widget _layout(Widget? current, List<Widget> previous) => Stack(
    alignment: AlignmentDirectional.centerStart,
    children: [...previous, ?current],
  );

  static Widget _fade(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);

  static Widget _fadeAndRise(Widget child, Animation<double> animation) =>
      SlideTransition(
        position: Tween(
          begin: const Offset(0, _rise),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: _fade(child, animation),
      );
}

class _Reconnecting extends StatelessWidget {
  const _Reconnecting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.outline;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          SizedBox.square(
            dimension: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
          ),
          Flexible(
            child: Text(
              TinodeChatStrings.of(context).reconnecting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
