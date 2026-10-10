import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/outgoing_attachment_providers.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// How far an outgoing attachment's upload got, as a ring; indeterminate
/// before it starts. The only part of the bubble that watches progress.
class UploadProgressRing extends ConsumerWidget {
  const UploadProgressRing({
    required this.topic,
    required this.clientId,
    required this.color,
    super.key,
  });

  final String topic;
  final String clientId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      uploadProgressControllerProvider(topic, clientId),
    );
    return Semantics(
      label: TinodeChatStrings.of(context).uploading,
      child: SizedBox.square(
        dimension: 32,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 3,
          color: color,
        ),
      ),
    );
  }
}
