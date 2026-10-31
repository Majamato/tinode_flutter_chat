import 'dart:math';

/// How many loudness values a voice message carries, as TinodeWeb and
/// Tindroid send them.
const voicePreviewLength = 96;

/// How often the recorder measures the loudness.
const voiceSampleInterval = Duration(milliseconds: 100);

/// A recorder's level in dBFS (0 at full scale, about −160 for silence) as
/// a linear amplitude, 0..1.
double amplitudeOfDbfs(double dbfs) =>
    dbfs.isFinite ? pow(10, min(dbfs, 0) / 20).toDouble() : 0;

/// The level, in dBFS, the live waveform draws as a dot; louder rises
/// from there to full height at 0 dB.
const liveWaveformFloor = -50.0;

/// A bar of the live waveform while recording, 0..1, from the level in
/// [dbfs] on a fixed scale from [liveWaveformFloor] to 0 dB, so a loud
/// sample doesn't resize the others. Silence (or −∞) is 0.
double liveBarOf(double dbfs) => dbfs.isFinite
    ? ((dbfs - liveWaveformFloor) / -liveWaveformFloor).clamp(0, 1).toDouble()
    : 0;

/// The preview sent with a recording: the [samples] (linear amplitudes,
/// one per [voiceSampleInterval]) averaged into [voicePreviewLength]
/// buckets and scaled so the loudest is 100, as Tindroid does. Fewer
/// samples than buckets give one value per sample; none give none.
List<int> voicePreviewOf(List<double> samples) {
  final buckets = _averages(samples, min(samples.length, voicePreviewLength));
  final peak = buckets.fold<double>(0, max);
  if (peak <= 0) {
    return List.filled(buckets.length, 0);
  }
  return [for (final b in buckets) (100 * b / peak).round().clamp(0, 100)];
}

/// The [count] bars of a voice message's bubble from its [waveform]
/// (0..100 each): the mean of each stretch, scaled so the tallest is 1, as
/// TinodeWeb draws them. All 0 without a waveform, or when it is silent.
List<double> voiceBars(List<int> waveform, {int count = 26}) {
  if (waveform.isEmpty) {
    return List.filled(count, 0);
  }
  final bars = _averages([for (final w in waveform) w.toDouble()], count);
  final peak = bars.fold<double>(0, max);
  return [for (final b in bars) peak <= 0 ? 0 : b / peak];
}

/// [values] in [count] equal stretches, each the mean of its values. A
/// stretch narrower than one value takes the value it falls on.
List<double> _averages(List<double> values, int count) {
  if (values.isEmpty || count <= 0) {
    return const [];
  }
  final factor = values.length / count;
  return [
    for (var i = 0; i < count; i++)
      () {
        final lo = (i * factor).floor();
        final hi = max(((i + 1) * factor).floor(), lo + 1);
        var sum = 0.0;
        for (var j = lo; j < hi; j++) {
          sum += values[min(j, values.length - 1)];
        }
        return sum / (hi - lo);
      }(),
  ];
}
