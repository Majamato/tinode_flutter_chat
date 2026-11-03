import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/session/application/reconnecting_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A screen's [title] that turns into a small spinner and "Reconnecting…"
/// while the link is being restored, and back once it is, as in Telegram.
/// The swap rises and grows a little on `springCurve`; with Reduce motion
/// it only fades. The text keeps the app bar's title style, muted to
/// `onSurfaceVariant`. Watches only whether the link is reconnecting.
class ReconnectingTitle extends ConsumerWidget {
  const ReconnectingTitle({required this.title, super.key});

  /// The screen's name, shown while connected.
  final Widget title;

  /// The spinner's size; the text sets the row's height.
  static const spinnerSize = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconnecting = ref.watch(reconnectingNoticeProvider);
    final theme = TinodeChatTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: still ? theme.fadeDuration : theme.springDuration,
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
        if (still) {
          return fade;
        }
        final spring = CurvedAnimation(
          parent: animation,
          curve: theme.springCurve,
        );
        return AnimatedBuilder(
          animation: spring,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 6 * (1 - spring.value)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * spring.value,
              child: child,
            ),
          ),
          child: fade,
        );
      },
      child: reconnecting
          ? const _Reconnecting(key: ValueKey(true))
          : KeyedSubtree(key: const ValueKey(false), child: title),
    );
  }
}

class _Reconnecting extends StatelessWidget {
  const _Reconnecting({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          SizedBox.square(
            dimension: ReconnectingTitle.spinnerSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          Flexible(
            child: Text(
              TinodeChatStrings.of(context).reconnecting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
