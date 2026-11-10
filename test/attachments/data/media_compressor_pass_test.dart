import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';

void main() {
  group('A video pass', () {
    test('first, not starting low, is at 720p and the bitrate asked', () {
      final pass = PluginMediaCompressor.videoPass(
        startsLow: false,
        smaller: false,
        bitrate: 1500000,
      );

      expect(pass, (low: false, bitrate: 1500000));
    });

    test('first, starting low, is at 480p and 80% of the bitrate', () {
      final pass = PluginMediaCompressor.videoPass(
        startsLow: true,
        smaller: false,
        bitrate: 1500000,
      );

      expect(pass, (low: true, bitrate: 1200000));
    });

    test('second, starting low, keeps its already cut bitrate', () {
      final pass = PluginMediaCompressor.videoPass(
        startsLow: true,
        smaller: true,
        bitrate: 933567,
      );

      expect(pass, (low: true, bitrate: 933567));
    });

    test('second, not starting low, is at 480p and its bitrate', () {
      final pass = PluginMediaCompressor.videoPass(
        startsLow: false,
        smaller: true,
        bitrate: 933567,
      );

      expect(pass, (low: true, bitrate: 933567));
    });
  });
}
