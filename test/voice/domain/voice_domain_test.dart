import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_note.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_playback.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_waveform.dart';

void main() {
  group('amplitudeOfDbfs', () {
    test('full scale is 1, −20 dB a tenth, silence and noise 0', () {
      expect(amplitudeOfDbfs(0), 1);
      expect(amplitudeOfDbfs(-20), closeTo(0.1, 1e-9));
      expect(amplitudeOfDbfs(3), 1);
      expect(amplitudeOfDbfs(double.negativeInfinity), 0);
      expect(amplitudeOfDbfs(double.nan), 0);
    });
  });

  group('voicePreviewOf', () {
    test('averages into 96 buckets, the loudest at 100', () {
      final samples = [for (var i = 0; i < 192; i++) i.isEven ? 0.2 : 0.4];
      final preview = voicePreviewOf(samples);
      expect(preview, hasLength(voicePreviewLength));
      expect(preview.toSet(), {100});

      final ramp = voicePreviewOf([for (var i = 0; i < 960; i++) i / 960]);
      expect(ramp, hasLength(96));
      expect(ramp.last, 100);
      expect(ramp.first, lessThan(2));
      for (var i = 1; i < ramp.length; i++) {
        expect(ramp[i], greaterThanOrEqualTo(ramp[i - 1]));
      }
    });

    test('a short recording keeps one value per sample', () {
      expect(voicePreviewOf([0.1, 0.5, 0.25]), [20, 100, 50]);
    });

    test('silence is all zeros; nothing is nothing', () {
      expect(voicePreviewOf([0, 0, 0]), [0, 0, 0]);
      expect(voicePreviewOf(const []), isEmpty);
    });
  });

  group('liveBarOf', () {
    test('a fixed scale from the floor to 0 dB, clamped', () {
      expect(liveBarOf(liveWaveformFloor), 0);
      expect(liveBarOf(-60), 0);
      expect(liveBarOf(-25), closeTo(0.5, 1e-9));
      expect(liveBarOf(0), 1);
      expect(liveBarOf(3), 1);
      expect(liveBarOf(double.negativeInfinity), 0);
      expect(liveBarOf(double.nan), 0);
    });
  });

  group('voiceBars', () {
    test('26 bars from 96 values, the tallest at 1', () {
      final waveform = [for (var i = 0; i < 96; i++) i < 48 ? 20 : 80];
      final bars = voiceBars(waveform);
      expect(bars, hasLength(26));
      expect(bars.first, closeTo(0.25, 1e-9));
      expect(bars.last, 1);
    });

    test('fewer values than bars stretch over them', () {
      expect(voiceBars([50, 100], count: 4), [0.5, 0.5, 1, 1]);
    });

    test('no waveform, or a silent one, gives flat bars', () {
      expect(voiceBars(const []), List<double>.filled(26, 0));
      expect(voiceBars(const [0, 0]), List<double>.filled(26, 0));
    });
  });

  test('voiceClock shows minutes and two-digit seconds', () {
    expect(voiceClock(Duration.zero), '0:00');
    expect(voiceClock(const Duration(seconds: 7, milliseconds: 900)), '0:07');
    expect(voiceClock(const Duration(minutes: 1, seconds: 42)), '1:42');
    expect(voiceClock(VoiceNote.maxDuration), '10:00');
  });

  test('VoicePlayback.progress is 0 until the duration is known', () {
    const playback = VoicePlayback(key: 'k', position: Duration(seconds: 1));
    expect(playback.progress, 0);
    expect(
      playback.copyWith(duration: const Duration(seconds: 4)).progress,
      0.25,
    );
    expect(
      playback
          .copyWith(
            duration: const Duration(seconds: 4),
            position: const Duration(seconds: 9),
          )
          .progress,
      1,
    );
  });
}
