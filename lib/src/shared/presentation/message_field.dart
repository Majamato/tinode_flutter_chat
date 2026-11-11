import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// A field to write a message in, on a piece of glass: a pill, its corners
/// `composerRadius` as it grows to more lines, up to five. One line of it
/// is as tall as a `RoundSendButton` beside it. Watches nothing.
class MessageField extends StatelessWidget {
  const MessageField({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: TinodeChatTheme.of(context).composerRadius,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          filled: false,
          // 22 px of text: as tall as the round buttons.
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 11,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        minLines: 1,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.send,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
