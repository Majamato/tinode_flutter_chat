import 'dart:math';

import 'package:collection/collection.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The seqs of a topic the cache has covered: fetched from the server, so
/// a seq inside that is not stored was deleted or never existed.
///
/// Sorted and disjoint; ranges that touch are joined.
final class SeqRanges with ValueObject {
  SeqRanges([Iterable<SeqRange> ranges = const []])
    : ranges = List.unmodifiable(_normalized(ranges));

  /// Reads the stored form, `[[low, high], …]`.
  factory SeqRanges.fromJson(List<Object?> json) => SeqRanges([
    for (final item in json)
      if (item case [final int low, final int high] when 0 < low && low < high)
        SeqRange(low, high),
  ]);

  static final empty = SeqRanges();

  final List<SeqRange> ranges;

  bool get isEmpty => ranges.isEmpty;

  /// The newest covered range.
  SeqRange? get top => ranges.lastOrNull;

  bool covers(int seq) => rangeContaining(seq) != null;

  SeqRange? rangeContaining(int seq) =>
      ranges.where((r) => r.contains(seq)).firstOrNull;

  /// The end (exclusive) of the nearest covered range wholly below [seq],
  /// where a gap below [seq] starts. Null when there is none.
  int? highestBelow(int seq) =>
      ranges.lastWhereOrNull((r) => r.high <= seq)?.high;

  SeqRanges add(SeqRange range) => SeqRanges([...ranges, range]);

  SeqRanges remove(SeqRange range) => SeqRanges([
    for (final r in ranges)
      if (r.high <= range.low || r.low >= range.high)
        r
      else ...[
        if (r.low < range.low) SeqRange(r.low, range.low),
        if (r.high > range.high) SeqRange(range.high, r.high),
      ],
  ]);

  List<List<int>> toJson() => [
    for (final r in ranges) [r.low, r.high],
  ];

  static List<SeqRange> _normalized(Iterable<SeqRange> ranges) {
    final sorted = ranges.toList()..sort((a, b) => a.low.compareTo(b.low));
    final result = <SeqRange>[];
    for (final range in sorted) {
      final last = result.lastOrNull;
      if (last != null && range.low <= last.high) {
        result.last = SeqRange(last.low, max(last.high, range.high));
      } else {
        result.add(range);
      }
    }
    return result;
  }

  @override
  List<Object?> get props => [ranges];
}
