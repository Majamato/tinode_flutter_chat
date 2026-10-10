import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_viewer_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// An image in a message, in the space its size asks for: shown at once
/// when inline, otherwise a placeholder while it downloads and a retry
/// button if that fails. A tap opens it full screen. Watches the image's
/// file.
class ImageBubbleContent extends ConsumerWidget {
  const ImageBubbleContent({required this.image, super.key});

  /// How wide images are shown in a bubble.
  static const width = 220.0;

  final ImageAttachment image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheWidth = (width * MediaQuery.devicePixelRatioOf(context)).round();
    final ImageProvider<Object>? provider;
    var failed = false;
    if (image.bytes case final bytes?) {
      provider = MemoryImage(bytes);
    } else {
      final file = ref.watch(attachmentFileProvider(image.ref!));
      provider = switch (file) {
        AsyncData(:final value) => localImage(value),
        _ => null,
      };
      failed = file is AsyncError;
    }

    return Semantics(
      image: true,
      label: image.name ?? TinodeChatStrings.of(context).imageLabel,
      child: SizedBox(
        width: width,
        height: width / image.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: switch (provider) {
            final provider? => GestureDetector(
              onTap: () =>
                  unawaited(ImageViewerScreen.open(context, image, provider)),
              child: Image(
                image: ResizeImage.resizeIfNeeded(cacheWidth, null, provider),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
            null => _Placeholder(
              onRetry: failed
                  ? () => ref.invalidate(attachmentFileProvider(image.ref!))
                  : null,
            ),
          },
        ),
      ),
    );
  }
}

/// Grey space with a spinner, or with a retry button after a failure.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: switch (onRetry) {
          final onRetry? => IconButton(
            tooltip: TinodeChatStrings.of(context).retry,
            icon: const Icon(Icons.refresh),
            onPressed: onRetry,
          ),
          null => const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        },
      ),
    );
  }
}
