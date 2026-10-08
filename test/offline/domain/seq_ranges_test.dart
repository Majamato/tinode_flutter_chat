import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/offline/domain/seq_ranges.dart';

void main() {
  test('ranges that touch or overlap join, sorted', () {
    final covered = SeqRanges(const [
      SeqRange(10, 12),
      SeqRange(1, 4),
      SeqRange(4, 6),
      SeqRange(11, 15),
    ]);
    expect(covered.ranges, const [SeqRange(1, 6), SeqRange(10, 15)]);
    expect(covered.top, const SeqRange(10, 15));
  });

  test('covers and finds the range of a seq', () {
    final covered = SeqRanges(const [SeqRange(1, 6), SeqRange(10, 15)]);
    expect([0, 1, 5, 6, 9, 10, 14, 15].map(covered.covers), [
      false,
      true,
      true,
      false,
      false,
      true,
      true,
      false,
    ]);
    expect(covered.rangeContaining(12), const SeqRange(10, 15));
  });

  test('highestBelow is where the gap below a seq starts', () {
    final covered = SeqRanges(const [SeqRange(1, 6), SeqRange(10, 15)]);
    expect(covered.highestBelow(10), 6);
    expect(covered.highestBelow(20), 15);
    expect(covered.highestBelow(5), isNull);
  });

  test('remove splits a range', () {
    final covered = SeqRanges(const [SeqRange(1, 10)]);
    expect(covered.remove(const SeqRange(4, 6)).ranges, const [
      SeqRange(1, 4),
      SeqRange(6, 10),
    ]);
    expect(covered.remove(const SeqRange(1, 10)).isEmpty, isTrue);
  });

  test('round trips through its stored form, dropping junk', () {
    final covered = SeqRanges(const [SeqRange(1, 6), SeqRange(10, 15)]);
    expect(SeqRanges.fromJson(covered.toJson()), covered);
    expect(
      SeqRanges.fromJson(const [
        [3, 2],
        'x',
        [0, 4],
        [5, 6],
      ]).ranges,
      const [SeqRange(5, 6)],
    );
  });
}
