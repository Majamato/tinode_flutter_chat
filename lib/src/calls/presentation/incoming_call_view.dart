import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_avatar.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat_list/chat_title.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// A call to the user, ringing: who calls, voice or video, and buttons to
/// accept or decline. Watches the call's topic and whether it has video.
class IncomingCallView extends ConsumerWidget {
  const IncomingCallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(
      callControllerProvider.select(
        (c) => c == null ? null : (topic: c.topic, audioOnly: c.audioOnly),
      ),
    );
    if (call == null) {
      return const SizedBox.shrink();
    }

    final strings = TinodeChatStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(callControllerProvider.notifier);

    return Material(
      color: colors.inverseSurface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              SizedBox.square(
                dimension: 96,
                child: FittedBox(child: ChatAvatar(topic: call.topic)),
              ),
              const SizedBox(height: 16),
              DefaultTextStyle.merge(
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.onInverseSurface,
                ),
                child: ChatTitle(topic: call.topic),
              ),
              const SizedBox(height: 8),
              Text(
                call.audioOnly
                    ? strings.incomingVoiceCall
                    : strings.incomingVideoCall,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onInverseSurface.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.icon(
                    onPressed: controller.decline,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    icon: const Icon(Icons.call_end),
                    label: Text(strings.declineCall),
                  ),
                  FilledButton.icon(
                    onPressed: () => unawaited(controller.accept()),
                    icon: Icon(call.audioOnly ? Icons.call : Icons.videocam),
                    label: Text(strings.acceptCall),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
