import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';

/// A profile's photo in a circle, or its initials when it has none, or a
/// person icon when there are no initials either. Watches nothing.
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
    final photo = this.photo;
    return CircleAvatar(
      radius: radius,
      backgroundImage: photo == null ? null : MemoryImage(photo.bytes),
      child: photo != null
          ? null
          : initials.isEmpty
          ? Icon(Icons.person, size: radius)
          : Text(initials),
    );
  }
}
