import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_photo_controller.dart';
import 'package:tinode_flutter_chat/src/profile/application/profile_save_controller.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/failure_text.dart';

/// Why saving the profile, or its new photo, failed, if it did.
class ProfileSaveErrorText extends ConsumerWidget {
  const ProfileSaveErrorText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FailureText(
    failure:
        ref.watch(profileSaveFailureProvider) ??
        ref.watch(profilePhotoFailureProvider),
  );
}
