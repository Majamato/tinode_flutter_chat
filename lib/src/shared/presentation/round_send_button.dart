import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Sends, from a round piece of glass. With something to send ([onSend])
/// it fills with the brand colour and its arrow spins in. Without, it
/// rests on the mic, which records a voice message ([onRecord]), or,
/// without that either, rests disabled. A spinner shows while [busy].
/// Watches nothing.
class RoundSendButton extends StatelessWidget {
  const RoundSendButton({
    required this.onSend,
    this.onRecord,
    this.busy = false,
    super.key,
  });

  static const _size = 44.0;

  /// Null when there is nothing to send.
  final VoidCallback? onSend;

  /// Null when voice messages can't be recorded here.
  final VoidCallback? onRecord;

  /// Something is on its way: the button spins and can't be pressed.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final (face, onPressed, tooltip) = switch ((onSend, onRecord)) {
      _ when busy => (null, null, strings.send),
      (final send?, _) => (_FaceKind.send, send, strings.send),
      (_, final record?) => (_FaceKind.mic, record, strings.recordVoiceMessage),
      _ => (_FaceKind.resting, null, strings.send),
    };
    return GlassSurface(
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: _size, height: _size),
        icon: face == null
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _Face(face: face),
      ),
    );
  }
}

enum _FaceKind {
  /// Nothing to send, no voice messages: the arrow, greyed.
  resting,

  /// Nothing to send: the mic.
  mic,

  /// Something to send: the arrow on the brand colour.
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
      width: RoundSendButton._size,
      height: RoundSendButton._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? theme.actionColor : Colors.transparent,
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
          size: ChatIconSize.standard,
          color: switch (face) {
            _FaceKind.send => theme.onActionColor,
            _FaceKind.mic => theme.iconColor,
            _FaceKind.resting => theme.iconPassiveColor,
          },
        ),
      ),
    );
  }
}
