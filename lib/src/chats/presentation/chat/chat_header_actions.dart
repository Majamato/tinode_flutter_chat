import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/calls/presentation/call_button.dart';
import 'package:tinode_flutter_chat/src/search/presentation/message_search_button.dart';
import 'package:tinode_flutter_chat/src/session/application/session_inputs.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_surface.dart';

/// The chat's app bar buttons on one island of glass, to leave the title
/// room: message search, then video and voice calls where calls are
/// possible and the host offers that kind. Search alone is a round button.
/// Watches only which calls are offered.
class ChatHeaderActions extends ConsumerWidget {
  const ChatHeaderActions({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (voice, video) = ref.watch(
      tinodeChatFeaturesProvider.select((f) => (f.voiceCalls, f.videoCalls)),
    );
    final calls = (voice || video) && ref.watch(callsAvailableProvider(topic));
    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MessageSearchButton(topic: topic),
            if (calls && video) CallButton(topic: topic, video: true),
            if (calls && voice) CallButton(topic: topic, video: false),
          ],
        ),
      ),
    );
  }
}
