import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';

void main() {
  final data = base64.encode([1, 2, 3]);

  test('decodes inline data, sharing the bytes of equal photos', () {
    final first = AvatarImage.tryParse(ProfilePhoto(data: data))!;
    final again = AvatarImage.tryParse(ProfilePhoto(data: data, type: 'jpg'))!;
    expect(first.bytes, [1, 2, 3]);
    expect(again, first);
    expect(identical(again.bytes, first.bytes), isTrue);
  });

  test('accepts base64 without padding', () {
    final unpadded = base64.encode([1, 2, 3, 4]).replaceAll('=', '');
    expect(AvatarImage.tryParse(ProfilePhoto(data: unpadded))?.bytes, [
      1,
      2,
      3,
      4,
    ]);
  });

  test('a photo given by ref keeps the ref', () {
    final photo = AvatarImage.tryParse(
      const ProfilePhoto(ref: '/v0/file/s/a.jpg'),
    )!;
    expect(photo.ref, '/v0/file/s/a.jpg');
    expect(photo.bytes, isNull);
    expect(
      photo,
      AvatarImage.tryParse(const ProfilePhoto(ref: '/v0/file/s/a.jpg')),
    );
  });

  test('inline data wins over a ref', () {
    final photo = AvatarImage.tryParse(
      const ProfilePhoto(data: 'AQID', ref: '/v0/file/s/a.jpg'),
    )!;
    expect(photo.bytes, [1, 2, 3]);
  });

  test('no data and no ref, or bad data, is no image', () {
    expect(AvatarImage.tryParse(null), isNull);
    expect(AvatarImage.tryParse(const ProfilePhoto(ref: '')), isNull);
    expect(
      AvatarImage.tryParse(const ProfilePhoto(data: 'not base64!')),
      isNull,
    );
  });
}
