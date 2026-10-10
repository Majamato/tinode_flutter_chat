import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinode_flutter_chat/src/attachments/application/attachment_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/local_image.dart';

/// A profile photo given by ref, in a circle: [fallback] (initials) until
/// it has downloaded, or if it can't. Watches the photo's file.
class RefPhotoAvatar extends ConsumerWidget {
  const RefPhotoAvatar({
    required this.photoRef,
    required this.fallback,
    this.radius,
    super.key,
  });

  final String photoRef;
  final Widget fallback;
  final double? radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(attachmentFileProvider(photoRef)).value;
    return CircleAvatar(
      radius: radius,
      backgroundImage: file == null ? null : localImage(file),
      child: file == null ? fallback : null,
    );
  }
}
