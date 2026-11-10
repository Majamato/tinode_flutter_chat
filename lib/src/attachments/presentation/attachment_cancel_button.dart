import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The X on an outgoing attachment that stops its compression or upload
/// and drops the message.
class AttachmentCancelButton extends StatelessWidget {
  const AttachmentCancelButton({
    required this.onCancel,
    required this.color,
    super.key,
  });

  static const _size = 44.0;

  final VoidCallback onCancel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: TinodeChatStrings.of(context).cancelUpload,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: _size, height: _size),
      onPressed: onCancel,
      icon: Icon(
        TinodeChatIcons.of(context).close,
        size: ChatIconSize.standard,
        color: color,
      ),
    );
  }
}
