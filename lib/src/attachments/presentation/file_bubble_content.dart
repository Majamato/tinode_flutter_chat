import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/file_download_controller.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/file_download_state.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/file_size_label.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A file in a message: an icon for its type, its name and size. A tap
/// downloads it, with progress, and opens it. Watches its download.
class FileBubbleContent extends ConsumerWidget {
  const FileBubbleContent({required this.file, required this.color, super.key});

  final FileAttachment file;

  /// Text color of the bubble.
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    final fileRef = file.ref;
    final download = fileRef == null
        ? const DownloadIdle()
        : ref.watch(fileDownloadControllerProvider(fileRef));
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: fileRef == null ? null : () => _open(context, ref, fileRef),
      borderRadius: BorderRadius.circular(8),
      child: Semantics(
        button: true,
        onTapHint: strings.openFile,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 40,
                child: switch (download) {
                  Downloading(:final fraction) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                  DownloadFailed() => Icon(Icons.error_outline, color: color),
                  _ => Icon(_iconFor(file.mimeType), color: color, size: 32),
                },
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name ?? strings.fileLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: color),
                    ),
                    Text(switch ((download, file.size)) {
                      (DownloadFailed(), _) => strings.downloadFailed,
                      (_, final size?) => fileSizeLabel(size),
                      _ => '',
                    }, style: textTheme.labelSmall?.copyWith(color: color)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Downloads the file if needed and opens it; says so when no app can.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    String fileRef,
  ) async {
    final opened = await ref
        .read(fileDownloadControllerProvider(fileRef).notifier)
        .open(mimeType: file.mimeType);
    if (!context.mounted || opened == null) {
      return;
    }
    if (!opened) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(TinodeChatStrings.of(context).cannotOpenFile)),
      );
    }
  }

  static IconData _iconFor(String? mimeType) => switch (mimeType) {
    final m? when m.startsWith('audio/') => Icons.audio_file_outlined,
    final m? when m.startsWith('video/') => Icons.video_file_outlined,
    final m? when m.startsWith('image/') => Icons.image_outlined,
    'application/pdf' => Icons.picture_as_pdf_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
