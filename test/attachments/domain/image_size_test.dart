import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/image_size.dart';

Uint8List bytes(List<int> values) => Uint8List.fromList(values);

List<int> be16(int value) => [value >> 8, value & 0xFF];

List<int> le16(int value) => [value & 0xFF, value >> 8];

List<int> le24(int value) => [value & 0xFF, value >> 8 & 0xFF, value >> 16];

List<int> be32(int value) => [...be16(value >> 16), ...be16(value & 0xFFFF)];

/// A JPEG with an EXIF block giving [orientation] (when set), then a
/// start-of-frame segment for [width] by [height].
Uint8List jpeg(int width, int height, {int? orientation}) {
  final exif = orientation == null
      ? <int>[]
      : [
          0xFF, 0xE1, ...be16(2 + 6 + 8 + 2 + 12 + 4), //
          ...'Exif'.codeUnits, 0, 0,
          // TIFF header, big-endian, IFD0 right after it.
          ...'MM'.codeUnits, 0, 42, ...be32(8),
          ...be16(1),
          // Orientation: tag 0x0112, SHORT, count 1, the value.
          ...be16(0x0112), ...be16(3), ...be32(1), ...be16(orientation), 0, 0,
          ...be32(0),
        ];
  return bytes([
    0xFF, 0xD8, //
    ...exif,
    // A comment segment to skip.
    0xFF, 0xFE, ...be16(5), 1, 2, 3,
    0xFF, 0xC0, ...be16(11), 8, ...be16(height), ...be16(width), 3, 0, 0,
  ]);
}

void main() {
  test('PNG', () {
    final png = bytes([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0, 0, 0, 13, ...'IHDR'.codeUnits,
      ...be32(640), ...be32(480), 8, 6, 0, 0, 0,
    ]);
    expect(imageSizeOf(png), (width: 640, height: 480));
  });

  test('GIF', () {
    final gif = bytes([...'GIF89a'.codeUnits, ...le16(32), ...le16(16), 0]);
    expect(imageSizeOf(gif), (width: 32, height: 16));
  });

  test('WebP, lossy and extended', () {
    final lossy = bytes([
      ...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits, //
      ...'VP8 '.codeUnits, 0, 0, 0, 0,
      0, 0, 0, 0x9D, 0x01, 0x2A, ...le16(400), ...le16(300),
    ]);
    expect(imageSizeOf(lossy), (width: 400, height: 300));

    final extended = bytes([
      ...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits, //
      ...'VP8X'.codeUnits, 10, 0, 0, 0,
      0, 0, 0, 0, ...le24(1919), ...le24(1079),
    ]);
    expect(imageSizeOf(extended), (width: 1920, height: 1080));
  });

  test('JPEG, upright and turned by EXIF', () {
    expect(imageSizeOf(jpeg(4000, 3000)), (width: 4000, height: 3000));
    expect(imageSizeOf(jpeg(4000, 3000, orientation: 1)), (
      width: 4000,
      height: 3000,
    ));
    // 6: taken with the phone upright, stored sideways.
    expect(imageSizeOf(jpeg(4000, 3000, orientation: 6)), (
      width: 3000,
      height: 4000,
    ));
  });

  test('other formats and cut headers are unknown', () {
    expect(imageSizeOf(bytes('hello world'.codeUnits)), isNull);
    expect(imageSizeOf(bytes([])), isNull);
    final whole = jpeg(4000, 3000, orientation: 6);
    // The last bytes after the width aren't needed.
    for (var length = 0; length < whole.length - 3; length++) {
      expect(
        imageSizeOf(Uint8List.sublistView(whole, 0, length)),
        isNull,
        reason: 'cut at $length',
      );
    }
  });
}
