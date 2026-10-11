import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_save_controller.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/change_password_tile.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/delete_account_tile.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_photo_button.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_save_button.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_save_error_text.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// The photo, the name and note fields with their save button, and the
/// account's actions. The fields start from the profile as first read;
/// it watches nothing after that.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).requireValue;
    _name = TextEditingController(text: profile.name);
    _note = TextEditingController(text: profile.note);
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final saved = TinodeChatStrings.of(context).profileSaved;
    final ok = await ref
        .read(profileSaveControllerProvider.notifier)
        .save(name: _name.text, note: _note.text);
    if (ok) {
      messenger.showSnackBar(SnackBar(content: Text(saved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = TinodeChatStrings.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        const Center(child: ProfilePhotoButton()),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: InputDecoration(labelText: strings.nameField),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: strings.noteField),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              const ProfileSaveErrorText(),
              const SizedBox(height: 16),
              ProfileSaveButton(onSave: () => unawaited(_save())),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const ChangePasswordTile(),
        const DeleteAccountTile(),
      ],
    );
  }
}
