import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_state.dart';
import 'package:tinode_flutter_chat/src/chats/domain/load_status.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

import '../../support/fixtures.dart';

ChatMessage msg(int seq, {String text = 'hi', bool own = false}) => ChatMessage(
  seq: seq,
  time: at(seq),
  content: PlainText(text),
  isOwn: own,
  from: own ? alice : bob,
);

void main() {
  const empty = ChatState.loading();

  test('merges messages in seq order', () {
    final state = empty.withMessages([msg(3), msg(1), msg(2)]);

    expect(state.seqs, [1, 2, 3]);
    expect(state.firstSeq, 1);
    expect(state.lastSeq, 3);
  });

  test('an equal message changes nothing', () {
    final state = empty.withMessages([msg(1), msg(2)]);

    expect(state.withMessages([msg(2)]), same(state));
  });

  test('a changed message keeps the same seqs list', () {
    final state = empty.withMessages([msg(1), msg(2)]);

    final edited = state.withMessages([msg(2, text: 'edited')]);

    expect(edited, isNot(same(state)));
    expect(edited.seqs, same(state.seqs));
    expect(edited.bySeq[2]!.content.text, 'edited');
  });

  test('a new seq replaces the seqs list', () {
    final state = empty.withMessages([msg(1)]);

    expect(state.withMessages([msg(2)]).seqs, isNot(same(state.seqs)));
  });

  test('the publish ack and its echo are one message', () {
    final ack = empty.withMessages([msg(5, own: true)]);

    final echoed = ack.withMessages([msg(5, own: true)]);

    expect(echoed, same(ack));
    expect(echoed.seqs, [5]);
  });

  test('ready and failed set the status', () {
    expect(empty.ready(hasOlder: true).status, LoadStatus.ready);
    expect(empty.ready(hasOlder: true).hasOlder, isTrue);
    expect(empty.failed(ChatFailure.timeout).status, LoadStatus.failed);
  });

  test('loading older is a no-op when unchanged', () {
    expect(empty.withLoadingOlder(loading: false), same(empty));
    final loading = empty.withLoadingOlder(loading: true);
    expect(loading.loadingOlder, isTrue);
    expect(
      loading.withLoadingOlder(loading: false, hasOlder: false).loadingOlder,
      isFalse,
    );
  });
}
