import 'package:tinode_dart_client/tinode_dart_client.dart';

const alice = 'usrAlice';
const bob = 'usrBob';
const carol = 'usrCarol';
const friends = 'grpFriends';
const channel = 'chnNews';

final epoch = DateTime.utc(2026, 10, 4, 9);

DateTime at(int minutes) => epoch.add(Duration(minutes: minutes));

Subscription chat(
  String topic, {
  String? name,
  int lastSeq = 0,
  int read = 0,
  DateTime? lastMessageAt,
  String mode = 'JRWPS',
  String? want,
  bool online = false,
}) => Subscription(
  topic: topic,
  lastSeq: lastSeq,
  read: read,
  lastMessageAt: lastMessageAt,
  online: online,
  public: Profile(name: name ?? topic),
  access: Access(
    want: AccessMode.parse(want ?? mode),
    given: AccessMode.parse(mode),
    mode: AccessMode.parse(mode),
  ),
);

DataMessage message(
  String topic,
  int seq, {
  String? from = bob,
  String? text,
  DateTime? time,
}) => DataMessage(
  topic: topic,
  seq: seq,
  from: from,
  time: time ?? at(seq),
  content: PlainText(text ?? 'message $seq'),
);

/// A member entry of [userId] in a chat's subscriptions.
Subscription member(
  String userId, {
  String? name,
  int read = 0,
  int received = 0,
  String mode = 'JRWPS',
}) => Subscription(
  userId: userId,
  read: read,
  received: received,
  public: name == null ? null : Profile(name: name),
  access: Access(
    want: AccessMode.parse(mode),
    given: AccessMode.parse(mode),
    mode: AccessMode.parse(mode),
  ),
);

/// The message that starts a call in [topic], from [from].
DataMessage callMessage(
  String topic,
  int seq, {
  String? from = bob,
  bool audioOnly = false,
  DateTime? time,
}) => DataMessage(
  topic: topic,
  seq: seq,
  from: from,
  time: time ?? at(seq),
  head: MessageHead(callState: CallState.started, audioOnly: audioOnly),
  content: const PlainText(' '),
);

/// The server's update of the call message [target] in [topic] to [state].
DataMessage callUpdate(
  String topic,
  int seq,
  int target,
  CallState state, {
  String? from = bob,
  Duration? duration,
}) => DataMessage(
  topic: topic,
  seq: seq,
  from: from,
  time: at(seq),
  head: MessageHead(
    replaces: ':$target',
    callState: state,
    callDuration: duration,
  ),
  content: const PlainText(' '),
);
