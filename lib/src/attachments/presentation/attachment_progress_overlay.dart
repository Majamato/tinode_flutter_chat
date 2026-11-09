import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_progress_ring.dart';

/// Laid over an outgoing photo or video while it compresses or uploads: a
/// dark scrim, the progress in numbers, and what is happening. Watches
/// nothing itself; its ring watches the progress.
class AttachmentProgressOverlay extends StatelessWidget {
  const AttachmentProgressOverlay({
    required this.topic,
    required this.clientId,
    required this.compress,
    super.key,
  });

  static const _scrim = Color(0x66000000);

  final String topic;
  final String clientId;

  /// Whether the attachment is still to compress, rather than to upload.
  final bool compress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _scrim,
      child: Center(
        child: AttachmentProgressRing(
          topic: topic,
          clientId: clientId,
          compress: compress,
          color: Colors.white,
          dimension: 52,
          label: true,
        ),
      ),
    );
  }
}
