import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The picked image (or the file's name and size) with a caption field,
/// before sending. Pops with the caption on Send, or with null. Watches
/// nothing.
class AttachmentPreviewScreen extends StatefulWidget {
  const AttachmentPreviewScreen({required this.file, super.key});

  /// Shows the preview of [file]; the caption, or null when cancelled.
  static Future<String?> open(BuildContext context, PickedFile file) =>
      Navigator.of(context).push(
        MaterialPageRoute<String>(
          builder: (_) => AttachmentPreviewScreen(file: file),
        ),
      );

  final PickedFile file;

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  void _send() => Navigator.of(context).pop(_caption.text);

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    final file = widget.file;
    final path = file.path;
    return Scaffold(
      appBar: AppBar(title: Text(file.name)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: file.isImage && path != null
                    ? Image.file(
                        File(path),
                        cacheWidth:
                            (MediaQuery.sizeOf(context).width *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                          Text(file.name, textAlign: TextAlign.center),
                          Text(fileSizeLabel(file.length)),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _caption,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: strings.captionHint,
                      ),
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    tooltip: strings.send,
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
