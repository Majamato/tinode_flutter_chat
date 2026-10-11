import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/change_password_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';

/// Opens the password change, and says so once it is done.
class ChangePasswordTile extends StatelessWidget {
  const ChangePasswordTile({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final changed = TinodeChatStrings.of(context).passwordChanged;
    if (await ChangePasswordScreen.open(context)) {
      messenger.showSnackBar(SnackBar(content: Text(changed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.password),
      title: Text(TinodeChatStrings.of(context).changePassword),
      onTap: () => unawaited(_open(context)),
    );
  }
}
