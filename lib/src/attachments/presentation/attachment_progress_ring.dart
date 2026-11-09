import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/attachment_progress.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// How far an outgoing attachment's compression or upload got: a ring with
/// the percentage inside, indeterminate while unknown. With [label], the
/// phase is written under it. Only it watches the progress.
class AttachmentProgressRing extends ConsumerWidget {
  const AttachmentProgressRing({
    required this.topic,
    required this.clientId,
    required this.compress,
    required this.color,
    this.dimension = 32,
    this.label = false,
    super.key,
  });

  final String topic;
  final String clientId;

  /// Whether the attachment is still to compress, rather than to upload.
  final bool compress;
  final Color color;

  /// The ring's size.
  final double dimension;

  /// Whether to write "Compressing…" or "Uploading…" under the ring.
  final bool label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = AttachmentProgress.shown(
      ref.watch(attachmentProgressControllerProvider(topic, clientId)),
      compress: compress,
    );
    final strings = TinodeChatStrings.of(context);
    final phase = switch (progress.phase) {
      AttachmentPhase.compressing => strings.compressing,
      AttachmentPhase.uploading => strings.uploading,
    };
    final percent = progress.percent;
    final ring = SizedBox.square(
      dimension: dimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: progress.fraction,
              strokeWidth: dimension / 12,
              color: color,
            ),
          ),
          if (percent != null)
            Text(
              '$percent%',
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: color,
                fontSize: dimension * 0.28,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
    return Semantics(
      label: phase,
      value: percent == null ? null : '$percent%',
      excludeSemantics: true,
      child: label
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ring,
                const SizedBox(height: 6),
                Text(
                  phase,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            )
          : ring,
    );
  }
}
