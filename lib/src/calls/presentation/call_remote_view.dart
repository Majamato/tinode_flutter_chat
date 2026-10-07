import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_status_text.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_video_view.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';

/// The peer: their video once it arrives in a video call, otherwise their
/// avatar, name and the call's status. Watches the remote stream and
/// whether the call has video.
class CallRemoteView extends ConsumerWidget {
  const CallRemoteView({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:stream, :audioOnly) = ref.watch(
      callControllerProvider.select(
        (c) => (stream: c?.remoteStream, audioOnly: c?.audioOnly ?? true),
      ),
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onCall = colors.onInverseSurface;
    if (stream != null && !audioOnly) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CallVideoView(stream: stream),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CallStatusText(
                  style: textTheme.titleMedium?.copyWith(color: onCall),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 96,
            child: FittedBox(child: ChatAvatar(topic: topic)),
          ),
          const SizedBox(height: 16),
          DefaultTextStyle.merge(
            style: textTheme.headlineSmall?.copyWith(color: onCall),
            child: ChatTitle(topic: topic),
          ),
          const SizedBox(height: 8),
          CallStatusText(
            style: textTheme.titleMedium?.copyWith(
              color: onCall.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
