import 'dart:typed_data';

/// An image's size in pixels, as it displays.
typedef ImageSize = ({int width, int height});

/// How many leading bytes [imageSizeOf] may need: a JPEG's size can sit
/// behind a large EXIF block.
const int imageHeaderLength = 256 * 1024;

/// The size of the JPEG, PNG, GIF or WebP image starting with [bytes]; null
/// for other formats or a header cut short. A JPEG's EXIF orientation is
/// applied: a photo taken sideways reports its upright size.
ImageSize? imageSizeOf(Uint8List bytes) {
  final header = _Header(bytes);
  if (header.startsWith(0, const [0x89, 0x50, 0x4E, 0x47]) && header.has(24)) {
    return (width: header.uint32(16), height: header.uint32(20));
  }
  if (header.startsWith(0, 'GIF8'.codeUnits) && header.has(10)) {
    return (
      width: header.uint16(6, Endian.little),
      height: header.uint16(8, Endian.little),
    );
  }
  if (header.startsWith(0, 'RIFF'.codeUnits) &&
      header.startsWith(8, 'WEBP'.codeUnits)) {
    return _webp(header);
  }
  if (header.startsWith(0, const [0xFF, 0xD8])) {
    return _jpeg(header);
  }
  return null;
}

ImageSize? _webp(_Header header) {
  final bytes = header.bytes;
  if (header.startsWith(12, 'VP8 '.codeUnits) && header.has(30)) {
    return (
      width: header.uint16(26, Endian.little) & 0x3FFF,
      height: header.uint16(28, Endian.little) & 0x3FFF,
    );
  }
  if (header.startsWith(12, 'VP8L'.codeUnits) && header.has(25)) {
    final b1 = bytes[22];
    final b2 = bytes[23];
    final b3 = bytes[24];
    return (
      width: 1 + (((b1 & 0x3F) << 8) | bytes[21]),
      height: 1 + (((b3 & 0x0F) << 10) | (b2 << 2) | ((b1 & 0xC0) >> 6)),
    );
  }
  if (header.startsWith(12, 'VP8X'.codeUnits) && header.has(30)) {
    int uint24(int at) => bytes[at] | bytes[at + 1] << 8 | bytes[at + 2] << 16;
    return (width: 1 + uint24(24), height: 1 + uint24(27));
  }
  return null;
}

ImageSize? _jpeg(_Header header) {
  final bytes = header.bytes;
  var rotated = false;
  var at = 2;
  while (header.has(at + 4)) {
    if (bytes[at] != 0xFF) {
      return null;
    }
    final marker = bytes[at + 1];
    if (marker == 0xFF) {
      // A fill byte.
      at++;
      continue;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) {
      // A marker without a length.
      at += 2;
      continue;
    }
    final length = header.uint16(at + 2);
    if (marker == 0xE1 && !rotated) {
      rotated = _exifSwapsSides(header, at + 4, at + 2 + length);
    }
    if (_isStartOfFrame(marker)) {
      if (!header.has(at + 9)) {
        return null;
      }
      final height = header.uint16(at + 5);
      final width = header.uint16(at + 7);
      return rotated
          ? (width: height, height: width)
          : (width: width, height: height);
    }
    at += 2 + length;
  }
  return null;
}

bool _isStartOfFrame(int marker) =>
    marker >= 0xC0 &&
    marker <= 0xCF &&
    marker != 0xC4 &&
    marker != 0xC8 &&
    marker != 0xCC;

/// Whether the EXIF block from [start] to [end] turns the image by 90°:
/// orientations 5 to 8.
bool _exifSwapsSides(_Header header, int start, int end) {
  if (!header.startsWith(start, const [0x45, 0x78, 0x69, 0x66, 0, 0])) {
    return false;
  }
  final tiff = start + 6;
  final Endian endian;
  if (header.startsWith(tiff, 'II'.codeUnits)) {
    endian = Endian.little;
  } else if (header.startsWith(tiff, 'MM'.codeUnits)) {
    endian = Endian.big;
  } else {
    return false;
  }
  if (!header.has(tiff + 8)) {
    return false;
  }
  final ifd = tiff + header.uint32(tiff + 4, endian);
  if (!header.has(ifd + 2) || ifd + 2 > end) {
    return false;
  }
  final entries = header.uint16(ifd, endian);
  for (var i = 0; i < entries; i++) {
    final entry = ifd + 2 + i * 12;
    if (!header.has(entry + 10) || entry + 10 > end) {
      return false;
    }
    if (header.uint16(entry, endian) == 0x0112) {
      final orientation = header.uint16(entry + 8, endian);
      return orientation >= 5 && orientation <= 8;
    }
  }
  return false;
}

/// Bounds-checked reads over the first bytes of a file.
final class _Header {
  _Header(this.bytes) : _data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData _data;

  /// Whether the first [length] bytes are there.
  bool has(int length) => length >= 0 && bytes.length >= length;

  bool startsWith(int at, List<int> prefix) {
    if (!has(at + prefix.length)) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[at + i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  int uint16(int at, [Endian endian = Endian.big]) =>
      _data.getUint16(at, endian);

  int uint32(int at, [Endian endian = Endian.big]) =>
      _data.getUint32(at, endian);
}
