import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';

/// The photo picked for a new group, uploaded only once the group is
/// created.
@immutable
final class GroupPhoto {
  const GroupPhoto({required this.file, required this.preview});

  final PickedFile file;

  /// The picked image, read once to show it before it is uploaded.
  final Uint8List preview;
}
