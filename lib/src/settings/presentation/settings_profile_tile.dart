import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_controller.dart';
import 'package:tinode_flutter_chat/src/profile/presentation/profile_screen.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/l10n/tinode_chat_strings.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/profile_avatar.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/settings_tile.dart';

/// The user's photo and name at the top of the settings, opening the
/// profile; "Profile" while it can't be read, e.g. offline. Watches the
/// profile.
class SettingsProfileTile extends ConsumerWidget {
  const SettingsProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = TinodeChatStrings.of(context);
    final profile = ref.watch(profileControllerProvider.select((p) => p.value));
    final name = profile?.name ?? '';
    return SettingsTile(
      minHeight: 76,
      leading: ProfileAvatar(
        initials: profile?.initials ?? '',
        photo: profile?.photo,
        radius: 28,
      ),
      title: name.isEmpty ? strings.profile : name,
      subtitle: strings.profileSubtitle,
      onTap: () => unawaited(
        ProfileScreen.open(context, backLabel: strings.settingsTitle),
      ),
    );
  }
}
