import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/ref_photo_avatar.dart';

/// A profile's photo in a circle, or its initials when it has none, or a
/// person icon when there are no initials either. Watches nothing itself;
/// a photo given by ref is downloaded by [RefPhotoAvatar].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.initials,
    this.photo,
    this.radius,
    super.key,
  });

  final String initials;
  final AvatarImage? photo;

  /// The circle's radius; [CircleAvatar]'s default when null.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final fallback = initials.isEmpty
        ? Icon(Icons.person, size: radius)
        : Text(initials);
    return switch (photo) {
      AvatarImage(:final bytes?) => CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      ),
      AvatarImage(:final ref?) => RefPhotoAvatar(
        photoRef: ref,
        fallback: fallback,
        radius: radius,
      ),
      _ => CircleAvatar(radius: radius, child: fallback),
    };
  }
}
