import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/send_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sends the composer's [text]. While it is blank the button rests on the
/// mic, which records a voice message ([onRecord]), or, without voice
/// messages, rests disabled. With text it fills with the brand colour and
/// its arrow spins in. (While recording, the recording panel takes the
/// composer's place, button and all.) A spinner shows while a message is
/// on its way. The only part of the composer that rebuilds for any of
/// these.
class SendButton extends ConsumerWidget {
  const SendButton({
    required this.topic,
    required this.text,
    required this.onSend,
    required this.onRecord,
    super.key,
  });

  static const _size = 40.0;

  final String topic;
  final TextEditingController text;
  final VoidCallback onSend;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sending = ref.watch(
      sendControllerProvider(topic).select((s) => s.isLoading),
    );
    final voice = ref.watch(
      tinodeChatFeaturesProvider.select((f) => f.voiceMessages),
    );
    final strings = TinodeChatStrings.of(context);
    if (sending) {
      return IconButton(
        onPressed: null,
        tooltip: strings.send,
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
        final (face, onPressed, tooltip) = switch ((ready, voice)) {
          (true, _) => (_FaceKind.send, onSend, strings.send),
          (_, true) => (_FaceKind.mic, onRecord, strings.recordVoiceMessage),
          _ => (_FaceKind.resting, null, strings.send),
        };
        return IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: _Face(face: face),
        );
      },
    );
  }
}

enum _FaceKind {
  /// Blank field, no voice messages: the arrow, greyed.
  resting,

  /// Blank field: the mic.
  mic,

  /// Text to send: the arrow on the brand colour.
  send,
}

/// The button's circle and glyph. The arrow and the mic turn in from a
/// quarter turn as they swap; the circle fills.
class _Face extends StatelessWidget {
  const _Face({required this.face});

  final _FaceKind face;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final theme = TinodeChatTheme.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final filled = face == _FaceKind.send;
    final arrow = face != _FaceKind.mic;
    return AnimatedContainer(
      duration: theme.fadeDuration,
      width: SendButton._size,
      height: SendButton._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? theme.ownBubbleColor : Colors.transparent,
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
          arrow ? icons.send : icons.microphone,
          key: ValueKey(arrow),
          color: filled
              ? theme.onOwnBubbleColor
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
