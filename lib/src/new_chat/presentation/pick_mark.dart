import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_members_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/chat_icon_size.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/icons/tinode_chat_icons.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// Whether the person named [topic] is picked for the new group: a ring,
/// or a filled circle with a tick that pops in on the spring (fades with
/// Reduce motion). Read out as checked or not. Watches that person.
class PickMark extends ConsumerWidget {
  const PickMark({required this.topic, super.key});

  static const _size = 24.0;

  final String topic;

  static Widget _pop(Widget child, Animation<double> animation) =>
      ScaleTransition(scale: animation, child: child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(
      newGroupMembersControllerProvider.select((m) => m.has(topic)),
    );
    final chat = TinodeChatTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      checked: picked,
      child: SizedBox.square(
        dimension: _size,
        child: AnimatedSwitcher(
          duration: reduceMotion ? chat.fadeDuration : chat.springDuration,
          switchInCurve: reduceMotion ? Curves.linear : chat.springCurve,
          transitionBuilder: reduceMotion
              ? AnimatedSwitcher.defaultTransitionBuilder
              : _pop,
          child: picked
              ? DecoratedBox(
                  key: const ValueKey(true),
                  decoration: BoxDecoration(
                    color: chat.actionColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      TinodeChatIcons.of(context).picked,
                      size: ChatIconSize.small,
                      color: chat.onActionColor,
                    ),
                  ),
                )
              : DecoratedBox(
                  key: const ValueKey(false),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}
