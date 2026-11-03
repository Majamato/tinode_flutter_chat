import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/calls/application/call_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/glass_icon_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Calls the peer of [topic], by voice or [video], from the chat's app bar.
/// Put it only where that call is possible and offered, on the glass island
/// of `ChatHeaderActions`; disabled while a call runs, which is all it
/// watches.
class CallButton extends ConsumerWidget {
  const CallButton({required this.topic, required this.video, super.key});

  final String topic;
  final bool video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icons = TinodeChatIcons.of(context);
    final busy = ref.watch(
      callControllerProvider.select((c) => c != null && !c.isOver),
    );
    final strings = TinodeChatStrings.of(context);
    return GlassIconButton(
      onPressed: busy
          ? null
          : () => unawaited(
              ref
                  .read(callControllerProvider.notifier)
                  .start(topic, audioOnly: !video),
            ),
      tooltip: video ? strings.videoCall : strings.voiceCall,
      icon: video ? icons.videoCall : icons.voiceCall,
      onGlass: true,
    );
  }
}
