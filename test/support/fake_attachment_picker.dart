import 'dart:convert';
import 'dart:typed_data';

import 'package:tinode_flutter_chat/src/attachments/data/attachment_picker.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';

/// An [AttachmentPicker] that hands out [next], once, whatever the source.
final class FakeAttachmentPicker implements AttachmentPicker {
  FakeAttachmentPicker({this.hasCamera = true});

  @override
  bool hasCamera;

  /// What the next pick returns; null as if the user cancelled.
  PickedFile? next;

  /// The sources asked for, in order.
  final picks = <AttachmentSource>[];

  @override
  Future<PickedFile?> pick(AttachmentSource source) async {
    picks.add(source);
    final file = next;
    next = null;
    return file;
  }
}

/// A picked file holding [bytes].
PickedFile pickedFile(
  String name,
  List<int> bytes, {
  String? mimeType,
  bool isImage = false,
}) => PickedFile(
  name: name,
  length: bytes.length,
  openRead: () => Stream.value(bytes),
  mimeType: mimeType,
  isImage: isImage,
);

/// A picked text file.
PickedFile pickedText(String name, String text) =>
    pickedFile(name, utf8.encode(text), mimeType: 'text/plain');

/// A 3×2 red PNG.
final pngBytes = Uint8List.fromList(const [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  3,
  0,
  0,
  0,
  2,
  8,
  6,
  0,
  0,
  0,
  157,
  116,
  102,
  26,
  0,
  0,
  0,
  17,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  248,
  207,
  192,
  240,
  31,
  134,
  25,
  144,
  57,
  0,
  155,
  126,
  11,
  245,
  114,
  176,
  185,
  60,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);
