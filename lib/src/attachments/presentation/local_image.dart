import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';

/// The image in [file]: read from memory, or from disk.
ImageProvider<Object> localImage(LocalFile file) => switch (file.bytes) {
  final bytes? => MemoryImage(bytes),
  null => FileImage(File(file.path!)),
};
