import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/new_group_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Creates the new group. Disabled while its [name] is blank or the group
/// is being created; the only part of the screen that rebuilds for either.
class CreateGroupButton extends ConsumerWidget {
  const CreateGroupButton({
    required this.name,
    required this.onCreate,
    super.key,
  });

  final TextEditingController name;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creating = ref.watch(
      newGroupControllerProvider.select((s) => s.isLoading),
    );
    final label = Text(TinodeChatStrings.of(context).createGroup);
    if (creating) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return ValueListenableBuilder(
      valueListenable: name,
      builder: (context, value, label) => TextButton(
        onPressed: value.text.trim().isEmpty ? null : onCreate,
        child: label!,
      ),
      child: label,
    );
  }
}
