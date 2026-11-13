import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_group_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/step_button.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Goes on from picking a new group's members to naming it. Enabled with
/// nobody picked too: a group may start with its owner alone. Watches
/// nothing.
class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StepButton(
      label: TinodeChatStrings.of(context).next,
      onPressed: () => NewGroupScreen.open(context),
    );
  }
}
