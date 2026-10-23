import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sends the composer's [text]. While it is blank the button rests,
/// disabled; with text it fills with the brand colour and its arrow spins
/// in. A spinner shows while a message is on its way. The only part of the
/// composer that rebuilds for either.
class SendButton extends ConsumerWidget {
  const SendButton({
    required this.topic,
    required this.text,
    required this.onSend,
    super.key,
  });

  static const _size = 40.0;

  final String topic;
  final TextEditingController text;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(
      sendControllerProvider(topic).select((s) => s.isLoading),
    );
    final tooltip = TinodeChatStrings.of(context).send;
    if (sending) {
      return IconButton(
        onPressed: null,
        tooltip: tooltip,
        icon: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ValueListenableBuilder(
      valueListenable: text,
      builder: (context, value, _) {
        final ready = value.text.trim().isNotEmpty;
        return IconButton(
          onPressed: ready ? onSend : null,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: _Face(ready: ready),
        );
      },
    );
  }
}

/// The button's circle and arrow; the arrow turns in from a quarter turn
/// as the circle fills.
class _Face extends StatelessWidget {
  const _Face({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = TinodeChatTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return AnimatedContainer(
      duration: theme.fadeDuration,
      width: SendButton._size,
      height: SendButton._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ready ? theme.ownBubbleColor : Colors.transparent,
      ),
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 300),
        switchInCurve: theme.springCurve,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: RotationTransition(
            turns: Tween<double>(
              begin: child.key == const ValueKey(true) ? 0.25 : -0.25,
              end: 0,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.4, end: 1).animate(animation),
              child: child,
            ),
          ),
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          key: ValueKey(ready),
          color: ready
              ? theme.onOwnBubbleColor
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
