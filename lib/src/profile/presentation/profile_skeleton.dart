import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_bone.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/skeleton/skeleton_shimmer.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The profile form's bones while the profile is read: the photo, the name
/// field and the save button, where the form puts them. Watches nothing.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = TinodeChatTheme.of(context);
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          const Center(child: SkeletonBone.circle(96)),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonBone.fill(height: 56, radius: chat.fieldRadius),
                const SizedBox(height: 24),
                SkeletonBone.fill(height: 54, radius: chat.buttonRadius),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
