import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/voice/domain/voice_seek_gate.dart';

void main() {
  late List<Duration> sent;
  late List<Completer<void>> landing;
  late VoiceSeekGate gate;

  setUp(() {
    sent = [];
    landing = [];
    gate = VoiceSeekGate((to) {
      sent.add(to);
      final done = Completer<void>();
      landing.add(done);
      return done.future;
    });
  });

  /// Lands the seek sent last.
  Future<void> land() async {
    landing.last.complete();
    await Future<void>.delayed(Duration.zero);
  }

  Duration s(int seconds) => Duration(seconds: seconds);
  Duration ms(int milliseconds) => Duration(milliseconds: milliseconds);

  test('quick seeks send one at a time and end on the last', () async {
    for (var i = 1; i <= 6; i++) {
      gate.seek(s(i));
    }
    expect(sent, [s(1)]);
    expect(gate.seeking, isTrue);

    await land();
    expect(sent, [s(1), s(6)]);

    await land();
    expect(sent, [s(1), s(6)]);
    expect(gate.seeking, isFalse);
  });

  test('positions are refused while a seek runs', () async {
    gate.seek(s(8));
    expect(gate.accepts(s(2), playing: true), isFalse);
    expect(gate.accepts(s(3), playing: true), isFalse);

    await land();
    expect(gate.accepts(s(8), playing: true), isTrue);
  });

  test('while playing, a position behind the one shown is refused', () {
    expect(gate.accepts(Duration.zero, playing: true), isTrue);
    expect(gate.accepts(ms(300), playing: true), isTrue);
    expect(gate.accepts(ms(120), playing: true), isFalse);
    expect(gate.accepts(ms(400), playing: true), isTrue);
  });

  test('after a seek back or a restart, it may go back', () async {
    expect(gate.accepts(s(9), playing: true), isTrue);
    gate.seek(s(2));
    await land();
    expect(gate.accepts(s(2), playing: true), isTrue);

    expect(gate.accepts(s(5), playing: true), isTrue);
    gate.restart();
    expect(gate.accepts(Duration.zero, playing: true), isTrue);
  });

  test('paused, every position shows', () {
    expect(gate.accepts(s(6), playing: false), isTrue);
    expect(gate.accepts(s(4), playing: false), isTrue);
  });

  test('a restart drops the target waiting for the running seek', () async {
    gate
      ..seek(s(1))
      ..seek(s(5))
      ..restart();

    await land();
    expect(sent, [s(1)]);
    expect(gate.seeking, isFalse);
  });

  test('a failed seek still sends the waiting one and ends', () async {
    gate
      ..seek(s(1))
      ..seek(s(4));
    landing.last.completeError(StateError('cannot seek'));
    await Future<void>.delayed(Duration.zero);
    expect(sent, [s(1), s(4)]);

    await land();
    expect(gate.seeking, isFalse);
  });
}
