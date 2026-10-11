import 'dart:async';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';

/// A scripted [TinodeSession]: chats and histories are plain fields, and
/// tests push server traffic with [emitMessage], [emitPresence] and
/// [emitInfo].
final class FakeTinodeSession implements TinodeSession {
  FakeTinodeSession({
    this.userId = 'usrAlice',
    Map<String, String>? passwords,
    List<Subscription>? chats,
    Map<String, List<DataMessage>>? histories,
    this.serverInfo = const ServerInfo(
      version: '0.25',
      iceServers: [
        IceServer(urls: ['stun:stun.example.com']),
      ],
      callTimeout: Duration(seconds: 30),
    ),
  }) : passwords = passwords ?? {'alice': 'alice123'},
       chats = chats ?? [],
       histories = histories ?? {};

  final String userId;
  final Map<String, String> passwords;
  final List<Subscription> chats;
  final Map<String, List<DataMessage>> histories;

  /// Every call, e.g. `attach usrBob` or `markRead usrBob 3`.
  final calls = <String>[];

  /// When set, `history` waits for it before answering.
  Completer<void>? holdHistory;

  /// When set, the next `chatList`, `history`, `publish` or
  /// `deleteMessages` throws it.
  Exception? failChatList;
  Exception? failHistory;
  Exception? failPublish;
  Exception? failDelete;

  /// What `find` answers, by the query it is sent. Unknown queries find
  /// nothing.
  final found = <String, List<FoundTopic>>{};

  /// When set, `find` waits for it before answering.
  Completer<void>? holdFind;

  /// When set, the next `find` or `createGroup` throws it.
  Exception? failFind;
  Exception? failCreateGroup;

  /// The user's own profile, the `public` of `me`.
  Profile? profile = const Profile(name: 'Alice');

  /// Logins taken by `createAccount`, with their passwords; [passwords]
  /// count as taken too.
  final accounts = <String, String>{};

  /// The login each email belongs to, for password resets.
  final emails = <String, String>{'alice@example.com': 'alice'};

  /// Whether new accounts need an email, as servers that send mail do;
  /// see [requireEmails].
  bool requireEmail = false;

  /// Makes new accounts need an email, and says so in [serverInfo].
  void requireEmails() {
    requireEmail = true;
    serverInfo = ServerInfo(
      version: serverInfo.version,
      iceServers: serverInfo.iceServers,
      callTimeout: serverInfo.callTimeout,
      requiredCredentials: const ['email'],
    );
  }

  /// The codes "mailed" to confirm new accounts' emails, by login; such a
  /// login can't log in without its code.
  final emailCodes = <String, String>{};

  /// The code `requestPasswordReset` "emailed", by address.
  final resetCodes = <String, String>{};

  /// The latest password `changePassword` set, and the login with it.
  String? changedPassword;
  String? changedLogin;

  /// Whether `deleteAccount` deleted the user.
  bool accountDeleted = false;

  /// The config the session was last opened with.
  TinodeConfig? config;

  /// The push token `setDeviceToken` set last.
  String? deviceToken;

  /// Thrown by the next `setDeviceToken`; it never completes while
  /// [holdDeviceToken] is set.
  Exception? failDeviceToken;
  bool holdDeviceToken = false;

  /// Chats deleted with `deleteChat`, and left with `leaveChat`.
  final deletedChats = <String>[];
  final leftChats = <String>[];

  /// The members `removeMember` removed, by group.
  final removedMembers = <String, List<String>>{};

  /// When set, the next such call throws it.
  Exception? failSignUp;
  Exception? failChangePassword;
  Exception? failResetPassword;
  Exception? failDeleteAccount;
  Exception? failProfile;
  Exception? failUpdateProfile;
  Exception? failDeleteChat;
  Exception? failRemoveMember;

  /// When set, `createAccount` and `updateProfile` wait for it.
  Completer<void>? holdSignUp;
  Completer<void>? holdUpdateProfile;

  /// Users that `addMember` refuses to add, as a server would without `S`.
  final refuseMembers = <String>{};

  /// The members `addMember` added, by group.
  final addedMembers = <String, List<String>>{};

  /// What `members` answers, by topic: the topic's subscriptions.
  final memberLists = <String, List<Subscription>>{};

  /// When set, the next `members` throws it.
  Exception? failMembers;
  var _groups = 0;

  /// The `ifModifiedSince` of the latest `chatList`.
  DateTime? lastChatListSince;

  /// The `head` of each `publish`, in order.
  final publishHeads = <Json?>[];

  /// When set, `publish` stores the message, then throws this instead of
  /// answering: the reply was lost with the link.
  Exception? loseNextAck;

  /// The deletions made through `deleteMessages`, by delete ID.
  final deleteLogs = <String, Map<int, List<SeqRange>>>{};

  /// For a restored session: whether the server answers. While false the
  /// session stays reconnecting until [comeOnline].
  bool reachable = true;
  String? _restoreToken;
  Exception? failStartCall;

  /// When set, `startCall` waits for it before answering.
  Completer<void>? holdStartCall;

  @override
  ServerInfo serverInfo;

  /// The payloads of `sendCallEvent`, in order.
  final callPayloads = <Json?>[];

  /// How many attaches hold each topic, like the real session counts them.
  final _holds = <String, int>{};

  /// Whether `publish` echoes the message back like the server does.
  bool echo = true;

  /// Whether a login succeeded, which `upload` and `download` need, like
  /// the client; set by the logins and by [comeOnline].
  bool loggedIn = false;

  /// Files on the server by ref: what `upload` stored and `download`
  /// serves. Tests put files here to receive them.
  final files = <String, Uint8List>{};
  var _uploads = 0;

  /// When set, `upload` waits for it before answering; an abort ends the
  /// wait.
  Completer<void>? holdUpload;

  /// When set, the next `upload` or `download` throws it, e.g. a
  /// `ServerUnreachableException` or a `ServerException`.
  Exception? failUpload;
  Exception? failDownload;

  /// When set, `upload` reports progress in chunks of this many bytes.
  int? uploadChunk;

  /// When set, `upload` reports each value added as the bytes sent so far,
  /// and answers once it is closed: the test drives the progress.
  StreamController<int>? uploadSteps;

  /// How long an upload's ref is good for, like the server's 60 s.
  Duration uploadLifetime = const Duration(seconds: 60);

  final _messages = StreamController<DataMessage>.broadcast(sync: true);
  final _presence = StreamController<PresMessage>.broadcast(sync: true);
  final _info = StreamController<InfoMessage>.broadcast(sync: true);
  // Sync, like the others: a fake made in `setUp` lives outside a widget
  // test's fake-async zone, where async callbacks would never run.
  final _statuses = StreamController<ConnectionStatus>.broadcast(sync: true);
  bool isClosed = false;
  ConnectionStatus _status = const Connected();

  String get token => 'token-$userId';

  void emitMessage(DataMessage message) => _messages.add(message);

  void emitPresence(PresMessage presence) => _presence.add(presence);

  void emitInfo(InfoMessage info) => _info.add(info);

  /// How many attaches currently hold [topic].
  int attachCount(String topic) => _holds[topic] ?? 0;

  /// Like the client, a session that reached [Disconnected] stays closed.
  void emitStatus(ConnectionStatus status) {
    if (status is Disconnected) {
      isClosed = true;
    }
    _status = status;
    _statuses.add(status);
  }

  /// Simulates the link ending for good, e.g. reconnecting turned off.
  void dropConnection({TinodeException? cause}) {
    if (isClosed) {
      return;
    }
    emitStatus(
      Disconnected(cause: cause ?? const ConnectionClosedException('gone')),
    );
  }

  @override
  Stream<DataMessage> get messages => _messages.stream;

  @override
  Stream<PresMessage> get presence => _presence.stream;

  @override
  Stream<InfoMessage> get info => _info.stream;

  @override
  ConnectionStatus get status => _status;

  @override
  Stream<ConnectionStatus> get statusChanges => _statuses.stream;

  @override
  void suspend() => calls.add('suspend');

  @override
  void resume({Duration? probeTimeout}) => calls.add(
    probeTimeout == null ? 'resume' : 'resume probe ${probeTimeout.inSeconds}s',
  );

  @override
  Future<LoginResult> loginBasic(
    String login,
    String password, {
    Map<String, String> codes = const {},
  }) async {
    calls.add(
      'loginBasic $login'
      '${codes.isEmpty ? '' : ' ${codes.values.join(',')}'}',
    );
    if ((passwords[login] ?? accounts[login]) != password) {
      throw const ServerException(401, 'authentication failed');
    }
    if (emailCodes[login] case final code?) {
      if (codes['email'] != code) {
        throw CredentialsRequiredException(const ['email'], userId: userId);
      }
      emailCodes.remove(login);
    }
    loggedIn = true;
    return LoginResult(userId: userId, token: token);
  }

  @override
  Future<LoginResult> loginToken(String token) async {
    calls.add('loginToken');
    if (token != this.token) {
      throw const ServerException(401, 'authentication failed');
    }
    loggedIn = true;
    return LoginResult(userId: userId, token: token);
  }

  /// Logs in as the fake's [userId] under the new [login].
  @override
  Future<LoginResult> createAccount({
    required String login,
    required String password,
    required Profile public,
    String? email,
  }) async {
    calls.add(
      'createAccount $login ${public.name}${email == null ? '' : ' $email'}',
    );
    await holdSignUp?.future;
    _requireConnected();
    if (failSignUp case final error?) {
      failSignUp = null;
      throw error;
    }
    if (passwords.containsKey(login) || accounts.containsKey(login)) {
      throw const ServerException(
        409,
        'duplicate credential',
        params: {'what': 'auth'},
      );
    }
    if (email == null && requireEmail) {
      throw const ServerException(422, 'policy violation');
    }
    if (email != null && !email.contains('@')) {
      throw const ServerException(400, 'malformed', params: {'what': 'email'});
    }
    if (emails.containsKey(email)) {
      throw const ServerException(409, 'duplicate credential');
    }
    accounts[login] = password;
    profile = public;
    if (email != null) {
      emails[email] = login;
      emailCodes[login] = '654321';
      throw CredentialsRequiredException(const ['email'], userId: userId);
    }
    loggedIn = true;
    return LoginResult(userId: userId, token: token);
  }

  @override
  Future<void> changePassword(String password, {String? login}) async {
    calls.add('changePassword${login == null ? '' : ' $login'}');
    _requireConnected();
    if (failChangePassword case final error?) {
      failChangePassword = null;
      throw error;
    }
    if (login != null && passwords.containsKey(login)) {
      throw const ServerException(409, 'duplicate credential');
    }
    changedPassword = password;
    changedLogin = login;
  }

  /// "Emails" the code `123456` when [email] is known; while that code is
  /// unused, another request is refused, as the server does.
  @override
  Future<void> requestPasswordReset(String email) async {
    calls.add('requestPasswordReset $email');
    _requireConnected();
    if (resetCodes.containsKey(email)) {
      throw const ServerException(409, 'duplicate credential');
    }
    if (emails.containsKey(email)) {
      resetCodes[email] = '123456';
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    calls.add('resetPassword $email $code');
    _requireConnected();
    if (failResetPassword case final error?) {
      failResetPassword = null;
      throw error;
    }
    if (resetCodes[email] != code) {
      throw const ServerException(401, 'authentication failed');
    }
    passwords[emails[email]!] = password;
    resetCodes.remove(email);
  }

  /// Kept even while not connected, as the client keeps it.
  @override
  Future<void> setDeviceToken(String? token) async {
    calls.add('deviceToken $token');
    deviceToken = token;
    if (holdDeviceToken) {
      await Completer<void>().future;
    }
    if (failDeviceToken case final error?) {
      failDeviceToken = null;
      throw error;
    }
  }

  /// Closes the session, as the server's eviction does.
  @override
  Future<void> deleteAccount() async {
    calls.add('deleteAccount');
    _requireConnected();
    if (failDeleteAccount case final error?) {
      failDeleteAccount = null;
      throw error;
    }
    accountDeleted = true;
    await close();
  }

  @override
  Future<TopicDescription?> description(String topic) async {
    calls.add('description $topic');
    _requireConnected();
    if (failProfile case final error?) {
      failProfile = null;
      throw error;
    }
    return topic == 'me' ? TopicDescription(public: profile) : null;
  }

  @override
  Future<void> updateProfile(Profile public) async {
    calls.add('updateProfile ${public.name}');
    await holdUpdateProfile?.future;
    _requireConnected();
    if (failUpdateProfile case final error?) {
      failUpdateProfile = null;
      throw error;
    }
    profile = public;
  }

  @override
  Future<String> attach(String topic) async {
    calls.add('attach $topic');
    _requireConnected();
    _holds.update(topic, (holds) => holds + 1, ifAbsent: () => 1);
    return topic;
  }

  @override
  Future<void> detach(String topic) async {
    calls.add('detach $topic');
    final holds = _holds.remove(topic) ?? 0;
    if (holds > 1) {
      _holds[topic] = holds - 1;
    }
  }

  @override
  Future<List<Subscription>> chatList({DateTime? ifModifiedSince}) async {
    calls.add('chatList');
    lastChatListSince = ifModifiedSince;
    _requireConnected();
    if (failChatList case final error?) {
      failChatList = null;
      throw error;
    }
    return List.of(chats);
  }

  @override
  Future<List<Subscription>> members(String topic, {String? userId}) async {
    calls.add('members $topic${userId == null ? '' : ' $userId'}');
    _requireConnected();
    if (failMembers case final error?) {
      failMembers = null;
      throw error;
    }
    return [
      for (final member in memberLists[topic] ?? const <Subscription>[])
        if (userId == null || member.userId == userId) member,
    ];
  }

  @override
  Future<List<FoundTopic>> find(String query) async {
    calls.add('find $query');
    await holdFind?.future;
    _requireConnected();
    if (failFind case final error?) {
      failFind = null;
      throw error;
    }
    return found[query] ?? const [];
  }

  /// Names the groups `grpNew1`, `grpNew2`… and adds each to [chats], as
  /// the next chat list sync would show it.
  @override
  Future<String> createGroup({required Profile public}) async {
    calls.add('createGroup ${public.name}');
    _requireConnected();
    if (failCreateGroup case final error?) {
      failCreateGroup = null;
      throw error;
    }
    final topic = 'grpNew${++_groups}';
    chats.add(
      Subscription(
        topic: topic,
        public: public,
        lastMessageAt: DateTime.utc(2026, 10, 4, 12),
        access: Access(
          want: AccessMode.parse('JRWPASDO'),
          given: AccessMode.parse('JRWPASDO'),
          mode: AccessMode.parse('JRWPASDO'),
        ),
      ),
    );
    _holds.update(topic, (holds) => holds + 1, ifAbsent: () => 1);
    return topic;
  }

  @override
  Future<void> addMember(String topic, String userId) async {
    calls.add('addMember $topic $userId');
    _requireConnected();
    if (refuseMembers.contains(userId)) {
      throw const ServerException(403, 'permission denied');
    }
    addedMembers.putIfAbsent(topic, () => []).add(userId);
  }

  @override
  Future<void> removeMember(String topic, String userId) async {
    calls.add('removeMember $topic $userId');
    _requireConnected();
    if (failRemoveMember case final error?) {
      failRemoveMember = null;
      throw error;
    }
    removedMembers.putIfAbsent(topic, () => []).add(userId);
    memberLists[topic]?.removeWhere((m) => m.userId == userId);
  }

  /// Drops the chat from [chats], as the server would.
  @override
  Future<void> deleteChat(String topic) async {
    calls.add('deleteChat $topic');
    _requireConnected();
    if (failDeleteChat case final error?) {
      failDeleteChat = null;
      throw error;
    }
    deletedChats.add(topic);
    chats.removeWhere((c) => c.topic == topic);
    _holds.remove(topic);
  }

  @override
  Future<void> leaveChat(String topic) async {
    calls.add('leaveChat $topic');
    _requireConnected();
    if (failDeleteChat case final error?) {
      failDeleteChat = null;
      throw error;
    }
    leftChats.add(topic);
    chats.removeWhere((c) => c.topic == topic);
    _holds.remove(topic);
  }

  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  }) async {
    calls.add(
      'history $topic'
      '${since == null ? '' : ' since $since'}'
      '${before == null ? '' : ' before $before'}',
    );
    await holdHistory?.future;
    _requireConnected();
    if (failHistory case final error?) {
      failHistory = null;
      throw error;
    }
    final all = [
      for (final m in histories[topic] ?? const <DataMessage>[])
        if ((before == null || m.seq < before) &&
            (since == null || m.seq >= since))
          m,
    ]..sort((a, b) => a.seq.compareTo(b.seq));
    return all.length <= limit ? all : all.sublist(all.length - limit);
  }

  @override
  Future<PublishResult> publish(
    String topic,
    MessageContent content, {
    Json? head,
  }) async {
    calls.add('publish $topic ${content.text}');
    publishHeads.add(head);
    _requireConnected();
    if (failPublish case final error?) {
      failPublish = null;
      throw error;
    }
    final ack = _store(
      topic,
      content,
      head: head == null ? null : MessageHead.fromJson(head),
    );
    if (loseNextAck case final error?) {
      loseNextAck = null;
      throw error;
    }
    return ack;
  }

  @override
  Future<int> deleteMessages(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
  }) async {
    calls.add(
      'delete $topic ${ranges.map((r) => '${r.low}-${r.high}').join(',')}'
      '${hard ? ' hard' : ''}',
    );
    _requireConnected();
    if (failDelete case final error?) {
      failDelete = null;
      throw error;
    }
    return recordDeletion(topic, ranges);
  }

  /// Deletes [ranges] from [topic]'s history as the server would, and
  /// returns the new delete ID.
  int recordDeletion(String topic, List<SeqRange> ranges) {
    histories[topic]?.removeWhere((m) => ranges.any((r) => r.contains(m.seq)));
    final log = deleteLogs.putIfAbsent(topic, () => {});
    final id = log.keys.fold(0, (max, id) => id > max ? id : max) + 1;
    log[id] = ranges;
    return id;
  }

  @override
  Future<DeleteLog> deleteLog(String topic, {int? since, int? limit}) async {
    calls.add('deleteLog $topic${since == null ? '' : ' since $since'}');
    _requireConnected();
    final entries = [
      for (final MapEntry(key: id, value: ranges)
          in (deleteLogs[topic] ?? const <int, List<SeqRange>>{}).entries)
        if (id >= (since ?? 0)) (id, ranges),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (entries.isEmpty) {
      return DeleteLog.empty;
    }
    return DeleteLog(
      lastDeleteId: entries.last.$1,
      ranges: [for (final (_, ranges) in entries) ...ranges],
    );
  }

  /// Starts like `TinodeClient.restore`: reconnecting, then logged in with
  /// [token] once [reachable].
  void restoreWith(String token) {
    calls.add('restore');
    _restoreToken = token;
    _status = const Reconnecting(attempt: 1, retryIn: Duration.zero);
    if (reachable) {
      Timer.run(comeOnline);
    }
  }

  /// The server answers a restored session: it logs in with the token.
  void comeOnline() {
    final token = _restoreToken;
    if (token == null || isClosed) {
      return;
    }
    loggedIn = token == this.token;
    emitStatus(
      token == this.token
          ? Connected(
              login: LoginResult(userId: userId, token: token),
            )
          : const Disconnected(cause: ServerException(401, 'expired')),
    );
  }

  /// Like the client, requests fail fast while the link is down.
  void _requireConnected() {
    if (_status is! Connected) {
      throw const ConnectionClosedException('not connected');
    }
  }

  @override
  Future<PublishResult> startCall(
    String topic, {
    required bool audioOnly,
  }) async {
    calls.add('startCall $topic ${audioOnly ? 'audio' : 'video'}');
    await holdStartCall?.future;
    if (failStartCall case final error?) {
      failStartCall = null;
      throw error;
    }
    return _store(
      topic,
      DraftyContent(Drafty.videoCall(audioOnly: audioOnly)),
      head: MessageHead(
        mime: MessageHead.draftyMime,
        callState: CallState.started,
        audioOnly: audioOnly,
      ),
    );
  }

  @override
  void sendCallEvent(String topic, int seq, CallEvent event, {Json? payload}) {
    if (_status is! Connected) {
      throw const ConnectionClosedException('not connected');
    }
    calls.add('call $topic $seq ${event.name}');
    callPayloads.add(payload);
  }

  /// Numbers [content] as the next message of [topic] and echoes it back.
  PublishResult _store(
    String topic,
    MessageContent content, {
    MessageHead? head,
  }) {
    final history = histories.putIfAbsent(topic, () => []);
    final seq = history.fold(0, (max, m) => m.seq > max ? m.seq : max) + 1;
    final time = DateTime.utc(2026, 10, 4, 12).add(Duration(seconds: seq));
    final sent = DataMessage(
      topic: topic,
      seq: seq,
      time: time,
      from: userId,
      head: head,
      content: content,
    );
    history.add(sent);
    if (echo) {
      scheduleMicrotask(() => emitMessage(sent));
    }
    return PublishResult(seq: seq, time: time);
  }

  /// Stores the file under `/v0/file/s/fakeN.<ext>`. Works in any link
  /// state once logged in, like the client.
  @override
  Future<UploadResult> upload(
    Stream<List<int>> Function() openRead, {
    required int length,
    required String filename,
    String? mimeType,
    void Function(int sent, int total)? onProgress,
    Future<void>? abortTrigger,
  }) async {
    calls.add('upload $filename');
    _requireLogin();
    var aborted = false;
    unawaited(abortTrigger?.then((_) => aborted = true));
    final bytes = BytesBuilder(copy: false);
    await openRead().forEach(bytes.add);
    final all = bytes.takeBytes();
    final step = uploadChunk ?? all.length;
    for (var sent = step; step > 0 && sent < all.length; sent += step) {
      onProgress?.call(sent, length);
      await Future<void>.delayed(Duration.zero);
    }
    if (uploadSteps case final steps?) {
      await for (final sent in steps.stream) {
        if (aborted) {
          break;
        }
        onProgress?.call(sent, length);
      }
    }
    onProgress?.call(all.length, length);
    if (holdUpload case final hold?) {
      await Future.any([hold.future, ?abortTrigger]);
    }
    await Future<void>.delayed(Duration.zero);
    if (aborted) {
      throw TransferAbortedException(Uri.parse('/v0/file/u/'));
    }
    if (failUpload case final error?) {
      failUpload = null;
      throw error;
    }
    final dot = filename.lastIndexOf('.');
    final ref =
        '/v0/file/s/fake${++_uploads}${dot < 0 ? '' : filename.substring(dot)}';
    files[ref] = all;
    return UploadResult(ref: ref, expires: clock.now().add(uploadLifetime));
  }

  @override
  Future<FileDownload> download(
    String ref, {
    Future<void>? abortTrigger,
  }) async {
    calls.add('download $ref');
    _requireLogin();
    if (failDownload case final error?) {
      failDownload = null;
      throw error;
    }
    final bytes = files[ref];
    if (bytes == null) {
      throw const ServerException(404, 'not found');
    }
    return FileDownload(bytes: Stream.value(bytes), length: bytes.length);
  }

  @override
  Uri? resolveFile(String ref) => ref.startsWith('javascript:')
      ? null
      : Uri.parse('https://tinode.test').resolve(ref);

  void _requireLogin() {
    if (!loggedIn) {
      throw StateError('Log in before transferring files.');
    }
  }

  @override
  void sendTyping(String topic) => calls.add('sendTyping $topic');

  @override
  void markRead(String topic, int seq) => calls.add('markRead $topic $seq');

  @override
  void markReceived(String topic, int seq) =>
      calls.add('markReceived $topic $seq');

  @override
  Future<void> close() async {
    calls.add('close');
    if (!isClosed) {
      emitStatus(const Disconnected());
    }
  }
}

/// A connector that hands out [session], or fails with [error].
SessionConnector connectTo(FakeTinodeSession session, {Exception? error}) =>
    (config) async {
      session.config = config;
      return error == null ? session : throw error;
    };

/// A restorer that hands out [session], started as `TinodeClient.restore`.
SessionRestorer restoreTo(FakeTinodeSession session) => (config, token) async {
  session.config = config;
  return session..restoreWith(token);
};
