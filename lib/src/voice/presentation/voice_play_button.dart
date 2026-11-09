import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The 44 px round button of a voice message: play, or pause while
/// [playing], or [busy] in its place (an upload's progress).
class VoicePlayButton extends StatelessWidget {
  const VoicePlayButton({
    required this.playing,
    required this.color,
    required this.iconColor,
    required this.onPressed,
    this.value,
    this.busy,
    super.key,
  });

  static const size = 44.0;

  final bool playing;

  /// The circle's colour.
  final Color color;
  final Color iconColor;
  final VoidCallback? onPressed;

  /// Read out after the label, e.g. the message's duration.
  final String? value;
  final Widget? busy;

  @override
  Widget build(BuildContext context) {
    final icons = TinodeChatIcons.of(context);
    final strings = TinodeChatStrings.of(context);
    final Widget face;
    if (busy case final busy?) {
      face = Padding(padding: const EdgeInsets.all(6), child: busy);
    } else {
      face = Icon(
        playing ? icons.pause : icons.play,
        color: iconColor,
        size: ChatIconSize.large,
      );
    }
    return Semantics(
      button: true,
      label: playing ? strings.pauseVoiceMessage : strings.playVoiceMessage,
      value: value,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: face),
          ),
        ),
      ),
    );
  }
}
