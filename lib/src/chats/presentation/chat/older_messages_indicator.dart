import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/chats/application/chat_controller.dart';

/// A small spinner above the oldest message while older ones load.
class OlderMessagesIndicator extends ConsumerWidget {
  const OlderMessagesIndicator({required this.topic, super.key});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(
      chatControllerProvider(topic).select((s) => s.loadingOlder),
    );
    if (!loading) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.all(12),
      child: Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
