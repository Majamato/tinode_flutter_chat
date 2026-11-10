import 'dart:async';
import 'dart:developer';
import 'dart:math' show max, min;
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/data/file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/data/media_compressor.dart';
import 'package:tinode_flutter_chat/src/attachments/data/memory_file_store.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/image_size.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/progress_throttle.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log.dart';
import 'package:tinode_flutter_chat/src/offline/data/call_log_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_database.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_session.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store.dart';
import 'package:tinode_flutter_chat/src/offline/domain/cached_call.dart';
import 'package:tinode_flutter_chat/src/offline/domain/chat_merge.dart';
import 'package:tinode_flutter_chat/src/offline/domain/client_id.dart';
import 'package:tinode_flutter_chat/src/offline/domain/history_page.dart';
import 'package:tinode_flutter_chat/src/offline/domain/latest_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_event.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outbox_retry.dart';
import 'package:tinode_flutter_chat/src/offline/domain/outgoing_message.dart';
import 'package:tinode_flutter_chat/src/offline/domain/tinode_cache_limits.dart';
import 'package:tinode_flutter_chat/src/search/domain/found_message.dart';
import 'package:tinode_flutter_chat/src/session/data/tinode_session.dart';
import 'package:tinode_flutter_chat/src/shared/domain/chat_failure.dart';

/// Messages fetched per page while looking for a message whose fate a drop
/// left unknown.
const _reconcilePage = 64;

/// How many delete-log pages one sync reads at most.
const _maxDeleteLogPages = 20;

/// Messages the latest catch-up fetches per chat: a chat's first page, as
/// `historyPageSize`, so opening it afterwards shows a full page at once.
const _latestPage = 32;

/// Chats the latest catch-up fetches at once.
const _latestConcurrency = 4;

/// A [ChatSession] over a remote [TinodeSession], a [ChatStore], a [FileStore]
/// and a [CallLog] (those two in memory unless given).
///
/// What the server sends is written to the store in arrival order; reads
/// wait for those writes, so they see everything that arrived before.
///
/// It prunes the cache to its `TinodeCacheLimits` once, when it starts:
/// reads wait for the messages, the files go after.
///
/// While [keepsPresence] is off it drops presence as it arrives: `pres on` /
/// `off` never reach [presence]'s listeners, and chats and descriptions
/// come without `online` or `seen`, which the store doesn't keep either.
///
/// The latest catch-up keeps the end of each chat as the server has it, for
/// the chat list's previews: after each chat list sync, and [latestDelay]
/// after a `pres msg` for a chat that isn't attached, it attaches each chat
/// the cache is behind on, newest first, a few at a time, catches it up
/// ([catchUp]) and detaches. It also fetches the members a preview needs: a
/// group's sender's name, and the counters for the user's own message.
///
/// The call log keeps every call message that passes through [history] or
/// arrives live, apart from the cache: what happens to the one can't cost
/// the other. It starts from the calls already cached. Deletions reach it
/// like they reach the cache, and a full chat list drops the calls of the
/// chats no longer in it.
///
/// With a [MediaCompressor], photos and videos are queued as picked and
/// compressed here, one at a time and whether online or not, before they
/// are uploaded: the compressor reports `CompressProgress`, then the
/// uploader `UploadProgress`. A video still over the attachment limits
/// once compressed is not sent. An app closed meanwhile compresses again
/// from the start.
final class CachedTinodeSession implements ChatSession {
  CachedTinodeSession(
    this._remote,
    this._store, {
    required this.userId,
    FileStore? files,
    CallLog? calls,
    TinodeCacheLimits limits = const TinodeCacheLimits(),
    this._compressor,
    this._attachmentLimits = const TinodeAttachmentLimits(),
    this.keepsPresence = true,
    this.latestDelay = const Duration(seconds: 1),
  }) : _files = files ?? MemoryFileStore(),
       _calls = calls ?? CallLog(CallLogDatabase(NativeDatabase.memory())) {
    // Before the pruning, which drops the oldest cached calls.
    unawaited(_write(_seedCallLog));
    unawaited(_prune(limits));
    _subscriptions = [
      _remote.messages.listen(_onMessage),
      _remote.presence.listen(_onPresence),
      _remote.info.listen(_onInfo),
      _remote.statusChanges.listen(_onStatus),
    ];
    if (_remote.status is Connected) {
      scheduleMicrotask(_kick);
    } else {
      // Compressing needs no link.
      scheduleMicrotask(() => unawaited(_runCompressions()));
    }
  }

  final TinodeSession _remote;
  final ChatStore _store;
  final FileStore _files;
  final CallLog _calls;
  final MediaCompressor? _compressor;
  final TinodeAttachmentLimits _attachmentLimits;

  /// How many times each chat was forgotten, so that a page asked for
  /// before that doesn't put its calls back: unlike the cache, the log
  /// doesn't prune chats that are gone.
  final _forgotten = <String, int>{};

  /// Downloads under way, by URL, shared by everyone asking.
  final _fetches = <String, _Fetch>{};
  late final List<StreamSubscription<Object>> _subscriptions;

  @override
  final String userId;

  final _outbox = StreamController<OutboxEvent>.broadcast(sync: true);
  final _deletions = StreamController<TopicDeletion>.broadcast(sync: true);
  final _storedChanges = StreamController<String>.broadcast(sync: true);

  /// The tail of the writes queued by arriving events.
  Future<void> _writes = Future.value();
  Future<List<Subscription>>? _chatListSync;
  var _closed = false;

  // Outbox drain state.
  var _draining = false;
  var _drainAgain = false;
  String? _sending;
  Timer? _retry;
  var _retryRound = 0;

  // Uploader state: one upload at a time, beside the drain.
  var _uploadLoop = false;
  var _uploadAgain = false;
  Timer? _uploadRetry;

  /// The message whose attachment is being uploaded, and how to stop it.
  String? _uploading;
  Completer<void>? _uploadAbort;

  // Compressor state: one photo or video at a time, beside the uploader.
  var _compressLoop = false;
  var _compressAgain = false;

  /// The message whose attachment is being compressed, and whether it was
  /// stopped.
  String? _compressing;
  var _compressStopped = false;

  // Latest catch-up state: the chats to catch up, in order, and those
  // being caught up now.
  final _latestQueue = <String>{};
  final _latestRunning = <String>{};

  /// Queued again while running: they run once more afterwards.
  final _latestAgain = <String>{};
  var _latestWorkers = 0;

  /// The attaches the app holds, by topic, those under way included: an
  /// open chat or a call catches its chat up itself, and gets its messages
  /// live, so the latest catch-up leaves it alone.
  final _held = <String, int>{};

  /// The `lastSeq` each chat was caught up to in this session, so a chat
  /// whose newest messages were deleted isn't fetched on every sync.
  final _latestFetchedAt = <String, int>{};

  /// A `pres msg` waits this long before its chat is caught up: a burst
  /// fetches once, and a fetch already under way (a call check) lands
  /// first.
  final Duration latestDelay;
  final _latestTimers = <String, Timer>{};

  // Passed through.

  @override
  Stream<DataMessage> get messages => _remote.messages;

  /// The presence events, less who came online or went offline while
  /// [keepsPresence] is off.
  @override
  Stream<PresMessage> get presence => _remote.presence.where(
    (p) =>
        keepsPresence ||
        (p.event != PresenceEvent.online && p.event != PresenceEvent.offline),
  );

  /// Whether to keep presence: who is online and when they were last seen.
  final bool keepsPresence;

  /// Forgets the last seen the store holds, e.g. kept before the host
  /// turned presence off: what a sync merges in keeps the stored `seen`.
  void forgetLastSeen() {
    if (!_closed) {
      unawaited(_write(_store.forgetLastSeen));
    }
  }

  @override
  Stream<InfoMessage> get info => _remote.info;

  @override
  ConnectionStatus get status => _remote.status;

  @override
  Stream<ConnectionStatus> get statusChanges => _remote.statusChanges;

  @override
  ServerInfo get serverInfo => _remote.serverInfo;

  @override
  Future<UploadResult> upload(
    Stream<List<int>> Function() openRead, {
    required int length,
    required String filename,
    String? mimeType,
    void Function(int sent, int total)? onProgress,
    Future<void>? abortTrigger,
  }) => _remote.upload(
    openRead,
    length: length,
    filename: filename,
    mimeType: mimeType,
    onProgress: onProgress,
    abortTrigger: abortTrigger,
  );

  @override
  Future<FileDownload> download(String ref, {Future<void>? abortTrigger}) =>
      _remote.download(ref, abortTrigger: abortTrigger);

  @override
  Uri? resolveFile(String ref) => _remote.resolveFile(ref);

  @override
  Future<LoginResult> loginBasic(
    String login,
    String password, {
    Map<String, String> codes = const {},
  }) => _remote.loginBasic(login, password, codes: codes);

  @override
  Future<LoginResult> loginToken(String token) => _remote.loginToken(token);

  /// Counted in [_held] too, from the moment it is asked.
  @override
  Future<String> attach(String topic) async {
    _hold(topic);
    try {
      return await _remote.attach(topic);
    } on Object {
      _release(topic);
      rethrow;
    }
  }

  @override
  Future<void> detach(String topic) {
    _release(topic);
    return _remote.detach(topic);
  }

  @override
  bool isAttached(String topic) => _remote.isAttached(topic);

  void _hold(String topic) =>
      _held.update(topic, (holds) => holds + 1, ifAbsent: () => 1);

  void _release(String topic) {
    final holds = _held.remove(topic) ?? 0;
    if (holds > 1) {
      _held[topic] = holds - 1;
    }
  }

  @override
  void sendTyping(String topic) => _remote.sendTyping(topic);

  @override
  Future<List<FoundTopic>> find(String query) => _remote.find(query);

  /// The group reaches the cache with the next chat list sync.
  @override
  Future<String> createGroup({required Profile public}) async {
    final name = await _remote.createGroup(public: public);
    _hold(name);
    return name;
  }

  @override
  Future<void> addMember(String topic, String userId) =>
      _remote.addMember(topic, userId);

  @override
  Future<void> removeMember(String topic, String userId) async {
    await _remote.removeMember(topic, userId);
    await _write(() => _store.removeMember(topic, userId));
    _changed(topic);
  }

  @override
  Future<void> deleteChat(String topic) async {
    await _remote.deleteChat(topic);
    _held.remove(topic);
    await _write(() => _forgetChat(topic));
  }

  @override
  Future<void> leaveChat(String topic) async {
    await _remote.leaveChat(topic);
    _held.remove(topic);
    await _write(() => _forgetChat(topic));
  }

  @override
  Future<LoginResult> createAccount({
    required String login,
    required String password,
    required Profile public,
    String? email,
  }) => _remote.createAccount(
    login: login,
    password: password,
    public: public,
    email: email,
  );

  @override
  Future<void> changePassword(String password, {String? login}) =>
      _remote.changePassword(password, login: login);

  @override
  Future<void> requestPasswordReset(String email) =>
      _remote.requestPasswordReset(email);

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) => _remote.resetPassword(email: email, code: code, password: password);

  /// Closes this session too; the caller deletes the cache.
  @override
  Future<void> deleteAccount() async {
    await _remote.deleteAccount();
    await close();
  }

  @override
  Future<void> setDeviceToken(String? token) => _remote.setDeviceToken(token);

  @override
  Future<TopicDescription?> description(String topic) async {
    final description = await _remote.description(topic);
    return description == null || keepsPresence
        ? description
        : descriptionWithoutPresence(description);
  }

  @override
  Future<void> updateProfile(Profile public) => _remote.updateProfile(public);

  @override
  Future<PublishResult> publish(
    String topic,
    MessageContent content, {
    Json? head,
  }) => _remote.publish(topic, content, head: head);

  @override
  Future<int> deleteMessages(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
  }) => _remote.deleteMessages(topic, ranges, hard: hard);

  @override
  Future<DeleteLog> deleteLog(String topic, {int? since, int? limit}) =>
      _remote.deleteLog(topic, since: since, limit: limit);

  @override
  Future<PublishResult> startCall(String topic, {required bool audioOnly}) =>
      _remote.startCall(topic, audioOnly: audioOnly);

  @override
  void sendCallEvent(String topic, int seq, CallEvent event, {Json? payload}) =>
      _remote.sendCallEvent(topic, seq, event, payload: payload);

  @override
  void suspend() => _remote.suspend();

  @override
  void resume({Duration? probeTimeout}) =>
      _remote.resume(probeTimeout: probeTimeout);

  // Files.

  @override
  Future<LocalFile?> cachedFile(String ref, {bool keep = false}) async =>
      switch (_remote.resolveFile(ref)) {
        final url? => _files.cached(url, keep: keep),
        null => null,
      };

  @override
  Future<LocalFile> fetchFile(
    String ref, {
    bool keep = false,
    void Function(int received, int? total)? onProgress,
  }) async {
    final url =
        _remote.resolveFile(ref) ??
        (throw ArgumentError.value(ref, 'ref', 'is not an http(s) URL'));
    if (await _files.cached(url, keep: keep) case final file?) {
      return file;
    }
    final fetch = _fetches['$url'] ??= _Fetch(keep: keep, () async {
      final download = await _remote.download(ref);
      var received = 0;
      return _files.cache(
        url,
        keep: keep,
        download.bytes.map((chunk) {
          received += chunk.length;
          _fetches['$url']?.report(received, download.length);
          return chunk;
        }),
      );
    }, onDone: () => _fetches.remove('$url'));
    if (onProgress != null) {
      fetch.listeners.add(onProgress);
    }
    final LocalFile file;
    try {
      file = await fetch.result;
    } finally {
      if (onProgress != null) {
        fetch.listeners.remove(onProgress);
      }
    }
    if (keep && !fetch.keep) {
      // Joined a download into the cache: keep what it wrote.
      return await _files.cached(url, keep: true) ?? file;
    }
    return file;
  }

  @override
  Stream<OutboxEvent> get outbox => _outbox.stream;

  @override
  Stream<TopicDeletion> get deletions => _deletions.stream;

  @override
  Stream<String> get storedChanges => _storedChanges.stream;

  // Chat list.

  @override
  Future<List<Subscription>> storedChatList() async {
    await _writes;
    final chats = await _store.chats();
    return keepsPresence ? chats : chats.map(withoutPresence).toList();
  }

  /// Syncs the cached list with the server ("if modified since" the newest
  /// change it holds) and returns it. Overlapping calls share one sync.
  ///
  /// The cache keeps no presence. The server sends `online` in each chat of
  /// a full list, and with "if modified since" a stub (`{topic, online,
  /// acs: {}}`) for each unchanged chat that is online, so the chats it
  /// fetched online are exactly the ones that are.
  ///
  /// Then the latest catch-up fetches, in the background, the chats the
  /// cache is behind on.
  @override
  Future<List<Subscription>> chatList({DateTime? ifModifiedSince}) =>
      _chatListSync ??= _syncChatList().whenComplete(
        () => _chatListSync = null,
      );

  Future<List<Subscription>> _syncChatList() async {
    await _writes;
    final since = chatListWatermark(await _store.chats());
    // Read first: a call of a new chat may land while the list is fetched.
    final logged = since == null ? await _loggedTopics() : const <String>{};
    var fetched = await _remote.chatList(ifModifiedSince: since);
    if (!keepsPresence) {
      fetched = fetched.map(withoutPresence).toList();
    }
    if (since == null) {
      await _store.replaceChats(fetched);
      await _write(() => _forgetCallsOfChatsGone(logged, fetched));
    } else {
      await _store.mergeChats(fetched);
    }
    final online = {
      for (final chat in fetched)
        if (chat.online) chat.topic,
    };
    final chats = await _store.chats();
    _queueLatest(_newestFirst(chats));
    return [
      for (final chat in chats)
        withPresence(chat, online: online.contains(chat.topic)),
    ];
  }

  /// Drops the calls of the [logged] chats that a full list, [fetched], no
  /// longer has: they went while this log wasn't listening. An empty list
  /// proves nothing, and the log can't be fetched again.
  Future<void> _forgetCallsOfChatsGone(
    Set<String> logged,
    List<Subscription> fetched,
  ) async {
    if (fetched.isEmpty) {
      return;
    }
    final listed = {for (final chat in fetched) chat.topic};
    for (final topic in logged.difference(listed)) {
      await _calls.deleteChat(topic);
      _changed(topic);
    }
  }

  /// The topics of [chats] with messages, the newest message first.
  static List<String> _newestFirst(List<Subscription> chats) {
    final epoch = DateTime.utc(0);
    return [
      for (final chat
          in chats.where((c) => c.lastSeq > 0).toList()..sort(
            (a, b) =>
                (b.lastMessageAt ?? epoch).compareTo(a.lastMessageAt ?? epoch),
          ))
        chat.topic!,
    ];
  }

  // Members.

  @override
  Future<List<Subscription>> storedMembers(String topic) async {
    await _writes;
    return _store.members(topic);
  }

  /// Fetches the members and keeps them: a full list replaces the cached
  /// one, a single member is put or, when not one any more, removed.
  /// Returns what the cache then holds, merged.
  @override
  Future<List<Subscription>> members(String topic, {String? userId}) async {
    final fetched = await _remote.members(topic, userId: userId);
    await _write(() async {
      if (userId == null) {
        await _store.replaceMembers(topic, fetched);
      } else if (fetched.isEmpty) {
        await _store.removeMember(topic, userId);
      } else {
        await _store.putMember(topic, fetched.single);
      }
    });
    _changed(topic);
    if (userId == null) {
      return _store.members(topic);
    }
    return [?await _store.member(topic, userId)];
  }

  // History.

  /// Fetches from the server and keeps what came back, with the seqs the
  /// request covered.
  @override
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  }) async {
    final forgotten = _forgotten[topic];
    final page = await _remote.history(
      topic,
      limit: limit,
      since: since,
      before: before,
    );
    // Queued together: a deletion must not land between the two.
    unawaited(
      _write(
        () => _store.putMessages(
          topic,
          page,
          covering: _covered(page, since: since, before: before, limit: limit),
        ),
      ),
    );
    await _write(() async {
      if (_forgotten[topic] == forgotten) {
        await _calls.put(page);
      }
    });
    _changed(topic);
    return page;
  }

  @override
  Future<Map<String, LatestMessage>> storedLatestMessages({
    String? topic,
  }) async {
    await _writes;
    return _store.latestMessages(topic: topic);
  }

  @override
  Future<Map<String, Set<int>>> storedUncountedSeqs({String? topic}) async {
    await _writes;
    return _store.uncountedSeqs(topic: topic);
  }

  @override
  Future<List<CachedCall>> storedCalls({String? topic}) async {
    await _writes;
    return _calls.calls(topic: topic);
  }

  @override
  Future<HistoryPage> storedPage(String topic, {required int limit}) async {
    await _writes;
    final top = (await _store.coverage(topic)).top;
    if (top == null) {
      return const HistoryPage([], reachedStart: false);
    }
    final messages = await _store.messagesIn(
      topic,
      from: top.low,
      before: top.high,
      limit: limit,
    );
    return HistoryPage(
      messages,
      reachedStart: top.low <= 1 && messages.length < limit,
    );
  }

  @override
  Future<HistoryPage> olderPage(
    String topic, {
    required int before,
    required int limit,
  }) async {
    await _writes;
    var result = <DataMessage>[];
    var cursor = before;
    var reachedStart = false;
    // Each round either serves a covered range or fills the gap below it.
    for (var round = 0; round < 16 && result.length < limit; round++) {
      if (cursor <= 1) {
        reachedStart = true;
        break;
      }
      final covered = await _store.coverage(topic);
      final want = limit - result.length;
      if (covered.rangeContaining(cursor - 1) case final range?) {
        final cached = await _store.messagesIn(
          topic,
          from: range.low,
          before: cursor,
          limit: want,
        );
        result = [...cached, ...result];
        if (cached.length >= want) {
          break;
        }
        cursor = range.low;
        continue;
      }

      if (_remote.status is! Connected) {
        break;
      }
      final since = covered.highestBelow(cursor);
      final List<DataMessage> fetched;
      try {
        fetched = await history(
          topic,
          since: since,
          before: cursor,
          limit: want,
        );
      } on ConnectionClosedException {
        break;
      }
      result = [...fetched, ...result];
      if (fetched.length >= want) {
        break;
      }
      cursor = since ?? 1;
    }
    return HistoryPage(result, reachedStart: reachedStart);
  }

  @override
  Future<CatchUp> catchUp(String topic, {required int limit}) async {
    await _writes;
    final top = (await _store.coverage(topic)).top;
    if (top == null) {
      // Read first: the page may log calls of its own.
      final logged = (await _loggedTopics()).contains(topic);
      final page = await history(topic, limit: limit);
      if (logged) {
        // The log outlived the cache, and deletions may have gone by.
        await _syncDeletes(topic);
      } else {
        // Nothing kept to delete: deletions so far are already applied.
        final chat = await _store.chat(topic);
        await _store.setSyncedDeleteId(topic, chat?.lastDeleteId ?? 0);
      }
      return CatchUp(page, gap: true);
    }
    final page = await history(topic, since: top.high, limit: limit);
    await _syncDeletes(topic);
    return CatchUp(page, gap: page.length >= limit);
  }

  /// Applies the deletions made since the last one this cache applied.
  Future<void> _syncDeletes(String topic) async {
    try {
      var synced = await _store.syncedDeleteId(topic);
      for (var page = 0; page < _maxDeleteLogPages; page++) {
        final log = await _remote.deleteLog(topic, since: synced + 1);
        if (log.ranges.isEmpty || log.lastDeleteId <= synced) {
          return;
        }
        await _applyDeletion(topic, log.ranges);
        synced = log.lastDeleteId;
        await _store.setSyncedDeleteId(topic, synced);
      }
    } on Object catch (e, stackTrace) {
      // The next catch-up tries again; the messages stay meanwhile.
      _log('Could not sync deletions of $topic', e, stackTrace);
    }
  }

  Future<void> _applyDeletion(String topic, List<SeqRange> ranges) async {
    await _quietly(
      'Could not delete logged calls',
      () => _calls.deleteRanges(topic, ranges),
    );
    final deleted = await _store.messagesInRanges(topic, ranges);
    await _store.deleteMessages(topic, ranges);
    await _forgetKeptFiles(deleted);
    if (!_closed) {
      _deletions.add(TopicDeletion(topic, ranges));
    }
    _changed(topic);
  }

  // Outbox.

  @override
  Future<List<OutgoingMessage>> storedOutgoing(String topic) async => [
    for (final entry in await _store.outbox(topic: topic))
      if (entry.kind == OutboxKind.publish)
        entry.toOutgoing(sending: entry.clientId == _sending),
  ];

  @override
  Future<OutgoingMessage> send(String topic, MessageContent content) async {
    final entry = await _store.enqueuePublish(
      topic,
      newClientId(),
      content,
      clock.now().toUtc(),
    );
    final message = entry.toOutgoing();
    _emit(OutgoingChanged(message));
    _kick();
    return message;
  }

  @override
  Future<OutgoingMessage> sendAttachment(
    String topic,
    PickedFile file, {
    String caption = '',
  }) async {
    return sendStaged(topic, await stageAttachment(file), caption: caption);
  }

  @override
  Future<OutgoingAttachment> stageAttachment(PickedFile file) async {
    final limit = _remote.serverInfo.maxFileUploadSize;
    final compressor = _compressor;
    final videoLimit = _attachmentLimits.videoBytesLimit(limit);
    // A video that already fits goes as it is. A GIF would lose its motion.
    final compress =
        compressor != null &&
        (file.isVideo
            ? file.length > videoLimit
            : file.isImage && file.mimeType != 'image/gif');
    if (!compress && limit != null && file.length > limit) {
      throw FileTooLargeException(limit);
    }
    final pickedInfo = file.isVideo ? await _refuseUnfitSource(file) : null;
    final stagedId = await _files.stage(file.name, file.openRead());
    final staged = await _files.staged(stagedId);
    int? width;
    int? height;
    Duration? duration;
    Uint8List? poster;
    if (file.isVideo && compressor != null && staged != null) {
      final info =
          pickedInfo ??
          await _quietly<VideoInfo?>(
            'Could not read a video',
            () => compressor.videoInfo(staged),
          );
      if (info != null) {
        (width, height, duration) = (info.width, info.height, info.duration);
      }
      poster = await _quietly<Uint8List?>(
        'Could not take a video poster',
        () => compressor.videoPoster(staged),
      );
      // A phone's portrait video may report its frame as stored, on its
      // side; the poster is upright, as the compressed copy will be.
      (width, height) = _upright(width, height, poster);
    } else if (file.isImage && staged != null) {
      final size = imageSizeOf(await _header(staged));
      (width, height) = (size?.width, size?.height);
      if (compress) {
        poster = await _quietly<Uint8List?>(
          'Could not take a photo poster',
          () => compressor.imagePoster(staged, width: width, height: height),
        );
      }
    }
    return OutgoingAttachment(
      stagedId: stagedId,
      name: file.name,
      size: staged?.length ?? file.length,
      mimeType: file.mimeType,
      isImage: file.isImage,
      isVideo: file.isVideo,
      width: width,
      height: height,
      voice: file.voice,
      duration: duration,
      poster: poster,
      pendingCompression: compress,
    );
  }

  @override
  Future<OutgoingMessage> sendStaged(
    String topic,
    OutgoingAttachment attachment, {
    String caption = '',
  }) async {
    await _refuseUnfitVideo(attachment);
    final captioned = attachment.withCaption(caption.trim());
    final entry = await _store.enqueuePublish(
      topic,
      newClientId(),
      captioned.content,
      clock.now().toUtc(),
      attachment: captioned,
    );
    final message = entry.toOutgoing();
    _emit(OutgoingChanged(message));
    _kick();
    return message;
  }

  @override
  Future<void> discardStaged(OutgoingAttachment attachment) => _quietly(
    'Could not delete a staged file',
    () => _files.unstage(attachment.stagedId),
  );

  @override
  bool get canTrimVideos => _compressor != null;

  @override
  Stream<Uint8List?> videoFrames(
    PickedFile file, {
    required int count,
    required Duration duration,
  }) {
    final compressor = _compressor;
    final path = file.path;
    if (compressor == null || path == null) {
      return const Stream.empty();
    }
    return compressor.videoFrames(
      LocalFile.atPath(path, length: file.length),
      count: count,
      duration: duration,
    );
  }

  @override
  Future<OutgoingAttachment> trimStaged(
    OutgoingAttachment attachment,
    VideoTrim trim,
  ) async {
    final compressor = _compressor;
    Uint8List? poster;
    if (compressor != null && trim.start > Duration.zero) {
      if (await _files.staged(attachment.stagedId) case final staged?) {
        poster = await _quietly<Uint8List?>(
          'Could not take a video poster',
          () => compressor.videoPoster(staged, at: trim.start),
        );
      }
    }
    return attachment.trimmed(trim, poster: poster);
  }

  /// Refuses a picked video over [TinodeAttachmentLimits.maxSourceVideoBytes]
  /// or [TinodeAttachmentLimits.maxSourceVideoDuration], before it is
  /// copied in; returns what it read of it, when it could.
  Future<VideoInfo?> _refuseUnfitSource(PickedFile file) async {
    final limits = _attachmentLimits;
    if (file.length > limits.maxSourceVideoBytes) {
      throw FileTooLargeException(limits.maxSourceVideoBytes);
    }
    final compressor = _compressor;
    final path = file.path;
    if (compressor == null || path == null) {
      return null;
    }
    final info = await _quietly<VideoInfo?>(
      'Could not read a video',
      () => compressor.videoInfo(LocalFile.atPath(path, length: file.length)),
    );
    if (info != null && info.duration > limits.maxSourceVideoDuration) {
      throw VideoTooLongException(limits.maxSourceVideoDuration);
    }
    return info;
  }

  /// Refuses a whole video, its staged copy deleted, that can't fit the
  /// limit even compressed: a long one must come with its part chosen.
  Future<void> _refuseUnfitVideo(OutgoingAttachment attachment) async {
    if (!attachment.isVideo ||
        !attachment.pendingCompression ||
        attachment.trim != null) {
      return;
    }
    final duration = attachment.duration;
    final limit = _attachmentLimits.videoBytesLimit(
      _remote.serverInfo.maxFileUploadSize,
    );
    if (duration != null &&
        _attachmentLimits.estimatedVideoBytes(duration, attachment.size) >
            limit) {
      await discardStaged(attachment);
      throw FileTooLargeException(limit);
    }
  }

  /// [width] by [height] turned to match [poster]'s orientation, when the
  /// two disagree.
  static (int?, int?) _upright(int? width, int? height, Uint8List? poster) {
    final shown = poster == null ? null : imageSizeOf(poster);
    if (width == null || height == null || shown == null) {
      return (width, height);
    }
    final portrait = height > width;
    final shownPortrait = shown.height > shown.width;
    return portrait == shownPortrait || width == height
        ? (width, height)
        : (height, width);
  }

  @override
  Future<LocalFile?> stagedFile(String stagedId) => _files.staged(stagedId);

  /// The first bytes of [file], enough to read an image's size.
  Future<Uint8List> _header(LocalFile file) async {
    final header = BytesBuilder(copy: false);
    await for (final chunk in _files.read(file)) {
      header.add(chunk);
      if (header.length >= imageHeaderLength) {
        break;
      }
    }
    return header.takeBytes();
  }

  @override
  Future<void> retry(String clientId) async {
    final entry = await _store.outboxByClientId(clientId);
    if (entry == null || !entry.failed) {
      return;
    }
    await _store.updateOutbox(entry.id, attempts: 0, clearFailure: true);
    _emit(
      OutgoingChanged(entry.toOutgoing().withStatus(OutgoingStatus.queued)),
    );
    _kick();
  }

  @override
  Future<void> discard(String clientId) async {
    if (clientId == _sending) {
      throw StateError('The message is being sent.');
    }
    final entry = await _store.outboxByClientId(clientId);
    if (entry != null && await _store.removeOutbox(entry.id)) {
      if (clientId == _uploading) {
        _abortUpload();
      }
      if (clientId == _compressing) {
        _stopCompression();
      }
      if (entry.attachment case final attachment?) {
        await _quietly(
          'Could not delete a staged file',
          () => _files.unstage(attachment.stagedId),
        );
      }
      _emit(OutgoingDiscarded(entry.topic, clientId));
    }
  }

  @override
  Future<void> delete(
    String topic,
    List<SeqRange> ranges, {
    required bool forEveryone,
  }) async {
    if (ranges.isEmpty) {
      return;
    }
    unawaited(_write(() => _calls.deleteRanges(topic, ranges)));
    await _write(() async {
      final deleted = await _store.messagesInRanges(topic, ranges);
      await _store.deleteMessages(topic, ranges);
      await _store.enqueueDelete(
        topic,
        ranges,
        hard: forEveryone,
        createdAt: clock.now().toUtc(),
      );
      await _forgetKeptFiles(deleted);
    });
    if (!_closed) {
      _deletions.add(TopicDeletion(topic, ranges));
    }
    _changed(topic);
    _kick();
  }

  /// Read markers reach the server now if the topic is attached, which
  /// the server requires. Else they go to the outbox, which attaches it,
  /// once online.
  @override
  void markRead(String topic, int seq) {
    unawaited(_write(() => _store.advanceChat(topic, read: seq)));
    if (_remote.status is Connected && _remote.isAttached(topic)) {
      _remote.markRead(topic, seq);
    } else {
      unawaited(
        _write(() => _store.enqueueRead(topic, seq, clock.now().toUtc())),
      );
      _kick();
    }
  }

  /// Sent only while connected: a received marker isn't worth queueing,
  /// the chat list's next sync marks what came meanwhile.
  @override
  void markReceived(String topic, int seq) {
    if (_remote.status is Connected) {
      _remote.markReceived(topic, seq);
      unawaited(_write(() => _store.advanceChat(topic, received: seq)));
    }
  }

  /// Starts a drain, the uploader and the compressor, unless they are
  /// running, in which case they run again.
  void _kick() {
    unawaited(_drain());
    unawaited(_runUploads());
    unawaited(_runCompressions());
  }

  Future<void> _drain() async {
    if (_closed) {
      return;
    }
    if (_draining) {
      _drainAgain = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainAgain = false;
        if (_remote.status is! Connected) {
          return;
        }
        await _writes;
        final pending = [
          for (final entry in await _store.outbox())
            if (!entry.failed) entry,
        ];
        final topics = {for (final entry in pending) entry.topic};
        for (final topic in topics) {
          final entries = [
            for (final entry in pending)
              if (entry.topic == topic) entry,
          ];
          if (!await _drainTopic(topic, entries)) {
            return;
          }
        }
      } while (_drainAgain && !_closed);
    } on Object catch (e, stackTrace) {
      _log('The outbox stopped', e, stackTrace);
    } finally {
      _draining = false;
    }
  }

  /// Sends one topic's entries in order. False when the link went down.
  Future<bool> _drainTopic(String topic, List<OutboxEntry> entries) async {
    try {
      await _remote.attach(topic);
    } on Object catch (e) {
      switch (retryDecisionFor(e)) {
        case RetryDecision.waitForConnection:
          return false;
        case RetryDecision.retryLater || RetryDecision.reconcile:
          _scheduleRetry();
          return true;
        case RetryDecision.fail:
          // The topic is gone or closed to this user: nothing will go.
          for (final entry in entries) {
            await _giveUp(entry, ChatFailure.of(e));
          }
          return true;
      }
    }
    try {
      await _reconcile(topic, entries.where((e) => e.inFlight).toList());
      for (final entry in entries) {
        if (_closed) {
          return false;
        }
        // Reconciling may have completed it.
        final current = await _store.outboxEntry(entry.id);
        if (current == null || current.failed) {
          continue;
        }
        if (current.attachment?.needsUpload(clock.now()) ?? false) {
          // This chat waits for the upload; the others go on.
          unawaited(_runUploads());
          return true;
        }
        try {
          await _send(current);
          _retryRound = 0;
        } on Object catch (e) {
          switch (retryDecisionFor(e)) {
            case RetryDecision.waitForConnection:
              return false;
            case RetryDecision.reconcile:
              _scheduleRetry();
              return true;
            case RetryDecision.retryLater:
              final attempts = current.attempts + 1;
              if (attempts >= maxSendAttempts) {
                await _giveUp(current, ChatFailure.of(e));
                continue;
              }
              await _store.updateOutbox(
                current.id,
                attempts: attempts,
                inFlight: false,
              );
              _scheduleRetry();
              return true;
            case RetryDecision.fail:
              await _giveUp(current, ChatFailure.of(e));
          }
        }
      }
      return true;
    } on ConnectionClosedException {
      return false;
    } finally {
      unawaited(_remote.detach(topic).then((_) {}, onError: (_) {}));
    }
  }

  Future<void> _send(OutboxEntry entry) async {
    switch (entry.kind) {
      case OutboxKind.publish:
        final clientId = entry.clientId!;
        await _store.updateOutbox(
          entry.id,
          inFlight: true,
          sentAfterSeq: await _newestSeq(entry.topic),
        );
        _sending = clientId;
        _emit(OutgoingChanged(entry.toOutgoing(sending: true)));
        // With its ref now; the client lists the upload in the packet.
        final content = entry.attachment?.content ?? entry.content;
        try {
          final ack = await _remote.publish(
            entry.topic,
            content,
            head: {clientIdHeadKey: clientId},
          );
          await _complete(
            entry,
            DataMessage(
              topic: entry.topic,
              seq: ack.seq,
              time: ack.time,
              from: userId,
              head: MessageHead.fromJson({
                if (content is DraftyContent) 'mime': MessageHead.draftyMime,
                clientIdHeadKey: clientId,
              }),
              content: content,
            ),
          );
        } finally {
          _sending = null;
        }
      case OutboxKind.delete:
        final deleteId = await _remote.deleteMessages(
          entry.topic,
          entry.ranges,
          hard: entry.hard,
        );
        // Only the next delete ID can be recorded: anything between would
        // be deletions this cache has not applied yet.
        if (deleteId == await _store.syncedDeleteId(entry.topic) + 1) {
          await _store.setSyncedDeleteId(entry.topic, deleteId);
        }
        await _store.removeOutbox(entry.id);
      case OutboxKind.read:
        _remote.markRead(entry.topic, entry.seq!);
        await _store.removeOutbox(entry.id);
    }
  }

  /// Entries sent before a drop may have reached the server: look for
  /// their client IDs there before sending any again.
  Future<void> _reconcile(String topic, List<OutboxEntry> inFlight) async {
    final publishes = inFlight
        .where((e) => e.kind == OutboxKind.publish)
        .toList();
    if (publishes.isEmpty) {
      return;
    }
    final found = <String, DataMessage>{};
    var since = publishes.map((e) => e.sentAfterSeq).reduce(min) + 1;
    for (var page = 0; page < 10; page++) {
      final fetched = await history(topic, since: since, limit: _reconcilePage);
      for (final message in fetched) {
        if (clientIdOf(message.head) case final id?
            when message.from == userId) {
          found[id] = message;
        }
      }
      if (fetched.length < _reconcilePage) {
        break;
      }
      since = fetched.last.seq + 1;
    }
    for (final entry in publishes) {
      if (found[entry.clientId] case final message?) {
        await _complete(entry, message);
      } else {
        // Not on the server: safe to send again.
        await _store.updateOutbox(entry.id, inFlight: false);
      }
    }
    // Deletes and read markers are safe to repeat.
  }

  /// The server has [entry] as [message]. Its staged file, if any, moves
  /// into the file cache, or among the kept files for a voice message, so
  /// the sender never downloads it.
  Future<void> _complete(OutboxEntry entry, DataMessage message) async {
    final first = await _store.completePublish(entry, message);
    if (first) {
      if (entry.attachment case OutgoingAttachment(
        :final stagedId,
        :final ref?,
        :final voice,
      )) {
        if (_remote.resolveFile(ref) case final url?) {
          await _quietly(
            'Could not keep a sent file',
            () => _files.adopt(stagedId, url, keep: voice != null),
          );
        }
      }
    }
    await _store.advanceChat(
      message.topic,
      lastSeq: message.seq,
      read: message.seq,
      lastMessageAt: message.time,
    );
    if (first) {
      _emit(OutgoingSent(entry.clientId!, message));
    }
    _changed(message.topic);
  }

  Future<void> _giveUp(OutboxEntry entry, ChatFailure failure) async {
    switch (entry.kind) {
      case OutboxKind.publish:
        await _store.updateOutbox(entry.id, failure: failure, inFlight: false);
        _emit(
          OutgoingChanged(
            entry.toOutgoing().withStatus(
              OutgoingStatus.failed,
              failure: failure,
            ),
          ),
        );
      case OutboxKind.delete:
        // The messages are still there: fetch them again.
        await _store.removeOutbox(entry.id);
        await _store.uncover(entry.topic, entry.ranges);
        if (!_closed) {
          _deletions.add(
            TopicDeletion(entry.topic, entry.ranges, restored: true),
          );
        }
      case OutboxKind.read:
        await _store.removeOutbox(entry.id);
    }
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(retryDelay(++_retryRound), _kick);
  }

  // Uploads.

  /// Uploads attachments one at a time, each once its message is next in
  /// its chat, until none waits or the link is down. Runs again when asked
  /// during a run; waits while a retry is scheduled.
  Future<void> _runUploads() async {
    if (_closed || (_uploadRetry?.isActive ?? false)) {
      return;
    }
    if (_uploadLoop) {
      _uploadAgain = true;
      return;
    }
    _uploadLoop = true;
    try {
      do {
        _uploadAgain = false;
        while (!_closed && _remote.status is Connected) {
          final next = await _nextUpload();
          if (next == null || !await _upload(next)) {
            break;
          }
        }
      } while (_uploadAgain && !_closed);
    } on Object catch (e, stackTrace) {
      _log('The uploader stopped', e, stackTrace);
    } finally {
      _uploadLoop = false;
    }
  }

  /// The first entry with an attachment to upload that leads its chat.
  Future<OutboxEntry?> _nextUpload() async {
    await _writes;
    final now = clock.now();
    final leaders = <String, OutboxEntry>{};
    for (final entry in await _store.outbox()) {
      if (!entry.failed) {
        leaders.putIfAbsent(entry.topic, () => entry);
      }
    }
    for (final entry in leaders.values) {
      if (entry.attachment case final attachment?
          when !entry.inFlight &&
              !attachment.pendingCompression &&
              attachment.needsUpload(now)) {
        return entry;
      }
    }
    return null;
  }

  /// Uploads [entry]'s attachment and keeps its ref. False when the
  /// uploader should stop: the link is down, the upload was cancelled, or
  /// a retry is scheduled.
  Future<bool> _upload(OutboxEntry entry) async {
    final attachment = entry.attachment!;
    final clientId = entry.clientId!;
    final staged = await _files.staged(attachment.stagedId);
    if (staged == null) {
      // The file is gone, e.g. the app's data was cleared.
      await _giveUp(entry, ChatFailure.unexpected);
      return true;
    }
    final abort = _uploadAbort = Completer<void>();
    _uploading = clientId;
    final throttle = ProgressThrottle();
    try {
      final result = await _remote.upload(
        () => _files.read(staged),
        length: staged.length,
        filename: attachment.name,
        mimeType: attachment.mimeType,
        abortTrigger: abort.future,
        onProgress: (sent, total) {
          if (throttle.admit(sent, total, clock.now())) {
            _emit(UploadProgress(entry.topic, clientId, sent, total));
          }
        },
      );
      // A fresh upload is trusted for a little while whatever its expiry
      // says, so it is never uploaded again before it could be sent.
      final now = clock.now();
      final soonest = now.add(OutgoingAttachment.expiryMargin * 2);
      final expires = result.expires ?? now.add(const Duration(minutes: 1));
      await _store.setOutboxAttachment(
        entry.id,
        attachment.uploaded(
          result.ref,
          expires.isBefore(soonest) ? soonest : expires,
        ),
      );
      unawaited(_drain());
      return true;
    } on TransferAbortedException {
      // Discarded, or the link went down: nothing to report.
      return false;
    } on Object catch (e) {
      switch (retryDecisionFor(e)) {
        case RetryDecision.waitForConnection:
          return false;
        case RetryDecision.retryLater || RetryDecision.reconcile:
          final attempts = entry.attempts + 1;
          if (attempts >= maxSendAttempts) {
            await _giveUp(entry, ChatFailure.of(e));
            return true;
          }
          await _store.updateOutbox(entry.id, attempts: attempts);
          _uploadRetry?.cancel();
          _uploadRetry = Timer(retryDelay(attempts), _kick);
          return false;
        case RetryDecision.fail:
          await _giveUp(entry, ChatFailure.of(e));
          return true;
      }
    } finally {
      _uploading = null;
      _uploadAbort = null;
    }
  }

  void _abortUpload() {
    if (_uploadAbort case final abort? when !abort.isCompleted) {
      abort.complete();
    }
  }

  // Compression.

  /// Compresses the outbox's photos and videos one at a time, oldest
  /// first, whether online or not. Runs again when asked during a run.
  Future<void> _runCompressions() async {
    if (_closed || _compressor == null) {
      return;
    }
    if (_compressLoop) {
      _compressAgain = true;
      return;
    }
    _compressLoop = true;
    try {
      do {
        _compressAgain = false;
        while (!_closed) {
          final next = await _nextCompression();
          if (next == null) {
            break;
          }
          await _compress(next);
        }
      } while (_compressAgain && !_closed);
    } on Object catch (e, stackTrace) {
      _log('The compressor stopped', e, stackTrace);
    } finally {
      _compressLoop = false;
    }
  }

  /// The oldest entry whose photo or video waits to be compressed.
  Future<OutboxEntry?> _nextCompression() async {
    await _writes;
    for (final entry in await _store.outbox()) {
      if (!entry.failed && (entry.attachment?.pendingCompression ?? false)) {
        return entry;
      }
    }
    return null;
  }

  /// Compresses [entry]'s photo or video and stages the result in place of
  /// the original, or marks it failed: too large, or not compressible.
  Future<void> _compress(OutboxEntry entry) async {
    final compressor = _compressor!;
    final attachment = entry.attachment!;
    final clientId = entry.clientId!;
    final staged = await _files.staged(attachment.stagedId);
    if (staged == null) {
      await _giveUp(entry, ChatFailure.unexpected);
      return;
    }
    _compressing = clientId;
    _compressStopped = false;
    _emit(
      CompressProgress(entry.topic, clientId, attachment.isVideo ? 0 : null),
    );
    try {
      final CompressedMedia output;
      try {
        output = attachment.isVideo
            ? await _compressVideo(compressor, staged, entry)
            : await compressor.compressImage(
                staged,
                _attachmentLimits,
                width: attachment.width,
                height: attachment.height,
              );
      } on CompressionCancelledException {
        return;
      }
      try {
        if (_compressStopped) {
          return;
        }
        await _adoptCompressed(entry, output);
      } finally {
        await _quietly('Could not delete a compressed file', output.delete);
      }
    } on Object catch (e, stackTrace) {
      _log('Could not compress an attachment', e, stackTrace);
      if (!_compressStopped && await _store.outboxEntry(entry.id) != null) {
        await _giveUp(entry, switch (e) {
          UnsupportedVideoFormatException() => ChatFailure.unsupportedFormat,
          _ => ChatFailure.unexpected,
        });
      }
    } finally {
      _compressing = null;
    }
  }

  /// [entry]'s video, [staged], compressed. Some encoders won't go as low
  /// as the bitrate asked (Android's minimum quality, on some phones, which
  /// is why Android starts at about 480p), so one over the limit is
  /// compressed once more, smaller and at a bitrate cut by as much as it
  /// overshot; its progress starts over.
  Future<CompressedMedia> _compressVideo(
    MediaCompressor compressor,
    LocalFile staged,
    OutboxEntry entry,
  ) async {
    final attachment = entry.attachment!;
    final first = await compressor.compressVideo(
      staged,
      _attachmentLimits,
      trim: attachment.trim,
      onProgress: _compressProgress(entry),
    );
    final limit = _compressedLimit(attachment);
    final asked = first.videoBitrate;
    final duration = attachment.duration;
    if (_compressStopped ||
        limit == null ||
        first.length <= limit ||
        asked == null ||
        duration == null) {
      return first;
    }
    await _quietly('Could not delete a compressed file', first.delete);
    _emit(CompressProgress(entry.topic, entry.clientId!, 0));
    return compressor.compressVideo(
      staged,
      _attachmentLimits,
      trim: attachment.trim,
      videoBitrate: _attachmentLimits.secondPassVideoBitrate(
        asked: asked,
        outputBytes: first.length,
        duration: duration,
        // Aims at the limit, not at its tolerance.
        limitBytes: _attachmentLimits.videoBytesLimit(
          _remote.serverInfo.maxFileUploadSize,
        ),
      ),
      smaller: true,
      onProgress: _compressProgress(entry),
    );
  }

  /// Reports a video's compression of [entry], at most every so often.
  void Function(double fraction) _compressProgress(OutboxEntry entry) {
    final throttle = ProgressThrottle();
    return (fraction) {
      final step = (fraction.clamp(0, 1) * 1000).round();
      if (!_compressStopped && throttle.admit(step, 1000, clock.now())) {
        _emit(CompressProgress(entry.topic, entry.clientId!, fraction));
      }
    };
  }

  /// The most [attachment] may weigh once compressed; null when unknown.
  int? _compressedLimit(OutgoingAttachment attachment) {
    final serverLimit = _remote.serverInfo.maxFileUploadSize;
    return attachment.isVideo
        ? _attachmentLimits.compressedVideoBytesLimit(serverLimit)
        : serverLimit;
  }

  /// Stages [output], [entry]'s compressed photo or video, in place of the
  /// original; one still over the limit is not sent.
  Future<void> _adoptCompressed(
    OutboxEntry entry,
    CompressedMedia output,
  ) async {
    final attachment = entry.attachment!;
    final limit = _compressedLimit(attachment);
    if (limit != null && output.length > limit) {
      await _giveUp(entry, ChatFailure.tooLarge);
      return;
    }
    final stagedId = await _files.stage(
      _withExtension(attachment.name, output.extension),
      output.openRead(),
    );
    var (width, height) = (output.width, output.height);
    if (attachment.isImage) {
      if (await _files.staged(stagedId) case final staged?) {
        final size = imageSizeOf(await _header(staged));
        (width, height) = (size?.width, size?.height);
      }
    }
    final compressed = attachment.compressed(
      stagedId: stagedId,
      name: _withExtension(attachment.name, output.extension),
      size: output.length,
      mimeType: output.mimeType,
      width: width,
      height: height,
    );
    final current = await _store.outboxEntry(entry.id);
    if (current == null || _compressStopped) {
      // Discarded meanwhile.
      await _quietly(
        'Could not delete a staged file',
        () => _files.unstage(stagedId),
      );
      return;
    }
    await _store.setOutboxAttachment(entry.id, compressed);
    await _quietly(
      'Could not delete a staged file',
      () => _files.unstage(attachment.stagedId),
    );
    if (await _store.outboxEntry(entry.id) case final updated?) {
      _emit(OutgoingChanged(updated.toOutgoing()));
    }
    unawaited(_runUploads());
    unawaited(_drain());
  }

  /// [name] with its extension replaced by [extension].
  static String _withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    return '${dot > 0 ? name.substring(0, dot) : name}$extension';
  }

  void _stopCompression() {
    _compressStopped = true;
    unawaited(
      _quietly('Could not stop a compression', () => _compressor!.cancel()),
    );
  }

  Future<int> _newestSeq(String topic) async {
    final chat = await _store.chat(topic);
    final top = (await _store.coverage(topic)).top;
    return max(chat?.lastSeq ?? 0, (top?.high ?? 1) - 1);
  }

  // Latest catch-up.

  /// The chat's `lastSeq` when the cache is behind it and this session
  /// hasn't caught it up that far yet; else null.
  Future<int?> _behindAt(String topic) async {
    final lastSeq = (await _store.chat(topic))?.lastSeq ?? 0;
    final top = (await _store.coverage(topic)).top;
    final covered = (top?.high ?? 1) - 1;
    return lastSeq > covered && lastSeq > (_latestFetchedAt[topic] ?? 0)
        ? lastSeq
        : null;
  }

  /// Queues [topics], in order, for the latest catch-up, and starts
  /// workers for them; with none, resumes what is queued.
  void _queueLatest(Iterable<String> topics) {
    if (_closed) {
      return;
    }
    for (final topic in topics) {
      if (_latestRunning.contains(topic)) {
        _latestAgain.add(topic);
      } else {
        _latestQueue.add(topic);
      }
    }
    if (_remote.status is! Connected) {
      // Resumed by the next connect.
      return;
    }
    final starts = min(
      _latestConcurrency - _latestWorkers,
      _latestQueue.length,
    );
    for (var i = 0; i < starts; i++) {
      _latestWorkers++;
      unawaited(_latestWorker());
    }
  }

  /// [topic] got a `pres msg`: caught up after [latestDelay], once for a
  /// burst.
  void _queueLatestSoon(String topic) {
    if (_closed || _latestTimers.containsKey(topic)) {
      return;
    }
    _latestTimers[topic] = Timer(latestDelay, () {
      _latestTimers.remove(topic);
      _queueLatest([topic]);
    });
  }

  Future<void> _latestWorker() async {
    try {
      while (!_closed &&
          _remote.status is Connected &&
          _latestQueue.isNotEmpty) {
        final topic = _latestQueue.first;
        _latestQueue.remove(topic);
        _latestRunning.add(topic);
        final bool linkUp;
        try {
          linkUp = await _catchUpLatest(topic);
        } finally {
          _latestRunning.remove(topic);
          if (_latestAgain.remove(topic)) {
            _latestQueue.add(topic);
          }
        }
        if (!linkUp) {
          // It and the rest wait for the next connect.
          _latestQueue.add(topic);
          return;
        }
      }
    } on Object catch (e, stackTrace) {
      _log('The latest catch-up stopped', e, stackTrace);
    } finally {
      _latestWorkers--;
    }
  }

  /// Catches [topic] up if the cache is behind it, with the members its
  /// preview needs. False when the link went down.
  Future<bool> _catchUpLatest(String topic) async {
    await _writes;
    final lastSeq = await _behindAt(topic);
    if (lastSeq == null || _closed || _held.containsKey(topic)) {
      return true;
    }
    try {
      await _remote.attach(topic);
    } on ConnectionClosedException {
      return false;
    } on Object catch (e, stackTrace) {
      _log('Could not attach $topic to catch it up', e, stackTrace);
      // Not again before it has news.
      _latestFetchedAt[topic] = lastSeq;
      return true;
    }
    try {
      final kind = TopicKind.of(topic);
      if (kind == TopicKind.group && (await _store.members(topic)).isEmpty) {
        // First, so the preview has the sender's name when it shows.
        await members(topic);
      }
      await catchUp(topic, limit: _latestPage);
      if (await _previewNeedsMembers(topic, kind)) {
        await members(topic);
      }
      _latestFetchedAt[topic] = lastSeq;
      return true;
    } on ConnectionClosedException {
      return false;
    } on Object catch (e, stackTrace) {
      _log('Could not catch up $topic', e, stackTrace);
      _latestFetchedAt[topic] = lastSeq;
      return true;
    } finally {
      unawaited(_remote.detach(topic).then((_) {}, onError: (_) {}));
    }
  }

  /// Whether the cached members can't name the sender of [topic]'s newest
  /// message in a group, or tell how far the user's own got; as
  /// `ChatPreviewController` reads them.
  Future<bool> _previewNeedsMembers(String topic, TopicKind kind) async {
    if (kind == TopicKind.channel) {
      return false;
    }
    final from = (await _store.latestMessages(
      topic: topic,
    ))[topic]?.message?.from;
    if (from == null) {
      return false;
    }
    final cached = await _store.members(topic);
    if (from == userId) {
      return cached.isEmpty;
    }
    return kind == TopicKind.group && !cached.any((m) => m.userId == from);
  }

  // Arriving events.

  void _onMessage(DataMessage message) {
    unawaited(_write(() => _storeLive(message)));
    unawaited(
      _write(() async {
        if (await _calls.put([message])) {
          _changed(message.topic);
        }
      }),
    );
  }

  Future<void> _storeLive(DataMessage message) async {
    await _store.putLive(message);
    final own = message.from == userId;
    await _store.advanceChat(
      message.topic,
      lastSeq: message.seq,
      read: own ? message.seq : null,
      lastMessageAt: message.time,
    );
    // The server moves a sender's own counters to their message.
    if (message.from case final from?) {
      await _store.advanceMember(
        message.topic,
        from,
        read: message.seq,
        received: message.seq,
      );
    }
    // The echo of an outbox message may beat the server's ack.
    if (clientIdOf(message.head) case final id? when own) {
      if (await _store.outboxByClientId(id) case final entry?) {
        await _complete(entry, message);
      }
    }
    _changed(message.topic);
  }

  void _onPresence(PresMessage presence) {
    final source = presence.source;
    switch (presence) {
      case PresMessage(topic: 'me', event: PresenceEvent.message, :final seq?)
          when source != null:
        unawaited(
          _write(
            () => _store.advanceChat(
              source,
              lastSeq: seq,
              lastMessageAt: clock.now().toUtc(),
            ),
          ),
        );
        _queueLatestSoon(source);
      case PresMessage(topic: 'me', event: PresenceEvent.read, :final seq?)
          when source != null:
        unawaited(_write(() => _store.advanceChat(source, read: seq)));
      case PresMessage(
            :final topic,
            event: PresenceEvent.deleted,
            :final deletedRanges,
          )
          when topic != 'me' && deletedRanges.isNotEmpty:
        unawaited(_write(() => _onDeleted(presence)));
      case PresMessage(topic: 'me', event: PresenceEvent.gone)
          when source != null:
        unawaited(_write(() => _forgetChat(source)));
      case PresMessage(topic: 'me', event: PresenceEvent.offline)
          when source != null && keepsPresence:
        // `off` carries no time and comes a few seconds late: close enough.
        // A full sync replaces it with the server's own `seen`.
        unawaited(
          _write(() => _store.advanceChat(source, seen: clock.now().toUtc())),
        );
      case _:
        break;
    }
  }

  /// Another member read or received more.
  void _onInfo(InfoMessage info) {
    switch (info) {
      case InfoMessage(
            :final topic,
            event: InfoEvent.read || InfoEvent.received,
            :final from?,
            :final seq?,
          )
          when topic != 'me':
        final read = info.event == InfoEvent.read;
        unawaited(
          _write(() async {
            await _store.advanceMember(
              topic,
              from,
              read: read ? seq : null,
              received: read ? null : seq,
            );
            _changed(topic);
          }),
        );
      case _:
        break;
    }
  }

  Future<void> _onDeleted(PresMessage presence) async {
    final topic = presence.topic;
    await _applyDeletion(topic, presence.deletedRanges);
    final deleteId = presence.lastDeleteId;
    if (deleteId != null &&
        deleteId == await _store.syncedDeleteId(topic) + 1) {
      await _store.setSyncedDeleteId(topic, deleteId);
    } else {
      // Deletions came in between: read them from the log.
      unawaited(_syncDeletes(topic));
    }
  }

  /// The chat was deleted, or this user left or was removed: its cache,
  /// calls, kept files and queued messages go.
  Future<void> _forgetChat(String topic) async {
    _forgotten.update(topic, (times) => times + 1, ifAbsent: () => 1);
    await _quietly(
      'Could not forget logged calls',
      () => _calls.deleteChat(topic),
    );
    _changed(topic);
    if (_uploading case final uploading?
        when (await _store.outboxByClientId(uploading))?.topic == topic) {
      _abortUpload();
    }
    if (_compressing case final compressing?
        when (await _store.outboxByClientId(compressing))?.topic == topic) {
      _stopCompression();
    }
    final stored = await _store.messagesInRanges(topic);
    final dropped = await _store.deleteChat(topic);
    await _forgetKeptFiles(stored);
    for (final entry in dropped) {
      if (entry.attachment case final attachment?) {
        await _quietly(
          'Could not delete a staged file',
          () => _files.unstage(attachment.stagedId),
        );
      }
      if (entry.clientId case final clientId?) {
        _emit(OutgoingDiscarded(topic, clientId));
      }
    }
  }

  /// Deletes the kept files of [messages]: their voice recordings. Those
  /// of messages no longer stored when deleted, e.g. pruned by
  /// `TinodeCacheLimits.messagesPerChat`, stay until logout.
  Future<void> _forgetKeptFiles(List<DataMessage> messages) async {
    for (final message in messages) {
      for (final attachment in MessageAttachment.listFrom(message.content)) {
        if (attachment case VoiceAttachment(:final ref?)) {
          if (_remote.resolveFile(ref) case final url?) {
            await _quietly(
              'Could not delete a kept file',
              () => _files.forget(url),
            );
          }
        }
      }
    }
  }

  void _onStatus(ConnectionStatus status) {
    if (status is Connected) {
      _retryRound = 0;
      _uploadRetry?.cancel();
      _kick();
      _queueLatest(const []);
    } else {
      // Started over on the next connect.
      _abortUpload();
    }
  }

  // Message search and pruning.

  @override
  Future<List<FoundMessage>> searchMessages(
    String topic,
    String match, {
    required int limit,
    int? before,
  }) async {
    await _writes;
    return _store.searchMessages(topic, match, limit: limit, before: before);
  }

  // The call log.

  /// Copies the cached calls into a log that has nothing yet: the calls of
  /// an app updated from before the log. All or none, so a start that
  /// doesn't get through this tries again next time.
  Future<void> _seedCallLog() async {
    if (await _calls.isEmpty) {
      await _calls.put(await _store.callMessages());
    }
  }

  /// The chats with logged calls; none when the log can't say.
  Future<Set<String>> _loggedTopics() async {
    try {
      return await _calls.topics();
    } on Object catch (e, stackTrace) {
      _log('Could not read the call log', e, stackTrace);
      return const {};
    }
  }

  Future<void> _prune(TinodeCacheLimits limits) async {
    await _write(() => _store.prune(keepPerChat: limits.messagesPerChat));
    try {
      final staged = {
        for (final entry in await _store.outbox()) ?entry.attachment?.stagedId,
      };
      await _files.prune(
        maxCacheBytes: limits.fileCacheBytes,
        keepStaged: staged,
      );
    } on Object catch (e, stackTrace) {
      _log('Could not prune the file cache', e, stackTrace);
    }
  }

  // Plumbing.

  /// Queues a store write behind the earlier ones. A failed write is
  /// logged: the cache misses it, the chat goes on.
  Future<void> _write(Future<void> Function() write) => _writes = _writes
      .then((_) => write())
      .catchError(
        (Object e, StackTrace stackTrace) =>
            _log('A cache write failed', e, stackTrace),
      );

  void _changed(String topic) {
    if (!_closed) {
      _storedChanges.add(topic);
    }
  }

  void _emit(OutboxEvent event) {
    if (!_closed) {
      _outbox.add(event);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _retry?.cancel();
    _uploadRetry?.cancel();
    _abortUpload();
    if (_compressing != null) {
      _stopCompression();
    }
    for (final timer in _latestTimers.values) {
      timer.cancel();
    }
    _latestTimers.clear();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    await _remote.close();
    await _writes;
    await _store.close();
    await _quietly('Could not close the call log', _calls.close);
    unawaited(_outbox.close());
    unawaited(_deletions.close());
    unawaited(_storedChanges.close());
  }

  /// The seqs a history request answered for: `since <= seq < before`, cut
  /// at the oldest message when the page was full.
  static SeqRange? _covered(
    List<DataMessage> page, {
    required int? since,
    required int? before,
    required int limit,
  }) {
    final low = page.length >= limit ? page.first.seq : (since ?? 1);
    final high = before ?? (page.isEmpty ? null : page.last.seq + 1);
    return high != null && high > low ? SeqRange(low, high) : null;
  }

  /// File and call log chores must not stop the rest: a failure is logged.
  /// What [action] gives; null, logged as [message], when it fails.
  static Future<T?> _quietly<T>(
    String message,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on Object catch (e, stackTrace) {
      _log(message, e, stackTrace);
      return null;
    }
  }

  static void _log(String message, Object error, StackTrace stackTrace) => log(
    message,
    name: 'tinode_flutter_chat',
    error: error,
    stackTrace: stackTrace,
  );
}

/// One download, with whoever follows its progress; [keep] when it goes
/// among the kept files.
final class _Fetch {
  _Fetch(
    Future<LocalFile> Function() run, {
    required this.keep,
    required void Function() onDone,
  }) {
    result = run().whenComplete(onDone);
  }

  final bool keep;
  late final Future<LocalFile> result;
  final listeners = <void Function(int received, int? total)>[];

  void report(int received, int? total) {
    for (final listener in List.of(listeners)) {
      listener(received, total);
    }
  }
}
