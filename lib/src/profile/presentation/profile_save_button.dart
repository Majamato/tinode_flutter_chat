import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_save_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/progress_button.dart';

/// Saves the profile's name and note; watches whether a save runs.
class ProfileSaveButton extends ConsumerWidget {
  const ProfileSaveButton({required this.onSave, super.key});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProgressButton(
      label: TinodeChatStrings.of(context).save,
      busy: ref.watch(profileSaveControllerProvider.select((s) => s.isLoading)),
      onPressed: onSave,
    );
  }
}
