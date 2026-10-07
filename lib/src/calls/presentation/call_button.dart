import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Calls the peer of [topic], by voice or [video]. Shown only where calls
/// are possible; watches that and whether a call is already running.
class CallButton extends ConsumerWidget {
  const CallButton({required this.topic, required this.video, super.key});

  final String topic;
  final bool video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(callsAvailableProvider(topic))) {
      return const SizedBox.shrink();
    }
    final busy = ref.watch(
      callControllerProvider.select((c) => c != null && !c.isOver),
    );
    final strings = TinodeChatStrings.of(context);
    return IconButton(
      onPressed: busy
          ? null
          : () => unawaited(
              ref
                  .read(callControllerProvider.notifier)
                  .start(topic, audioOnly: !video),
            ),
      tooltip: video ? strings.videoCall : strings.voiceCall,
      icon: Icon(video ? Icons.videocam : Icons.call),
    );
  }
}
