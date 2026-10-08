import 'package:tinode_dart_client/tinode_dart_client.dart';

/// Opens a [TinodeSession] to the server described by a [TinodeConfig].
typedef SessionConnector = Future<TinodeSession> Function(TinodeConfig config);

/// Starts a [TinodeSession] for a user who logged in before, without
/// waiting for the server: it connects and logs in with [token] in the
/// background, see `TinodeClient.restore`.
typedef SessionRestorer =
    Future<TinodeSession> Function(TinodeConfig config, String token);

/// The link to a Tinode server, as the rest of the package sees it.
///
/// It wraps `TinodeClient` (a final class that cannot be faked) so that
/// tests can swap in a fake, and so a cached or offline session can slot
/// in later. Names follow the glossary: a session *attaches* to a topic.
abstract interface class TinodeSession {
  Future<LoginResult> loginBasic(String login, String password);

  Future<LoginResult> loginToken(String token);

  /// Starts receiving the topic's live traffic; returns its real name.
  ///
  /// Attaches are counted: a chat screen and a call can hold the same
  /// topic, and it stays attached until every attach has been matched by a
  /// [detach]. A failed attach holds nothing.
  Future<String> attach(String topic);

  /// Releases one [attach]; the last one stops the topic's live traffic.
  /// The subscription stays.
  Future<void> detach(String topic);

  /// The chat list: the subscriptions of `me` that name a topic. With
  /// [ifModifiedSince], only the chats changed since; see
  /// `TinodeClient.getSubscriptions`.
  Future<List<Subscription>> chatList({DateTime? ifModifiedSince});

  /// Up to [limit] messages with `since <= seq < before`, the newest of
  /// them, oldest first.
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  });

  /// [head] adds headers, e.g. the outbox's client ID.
  Future<PublishResult> publish(
    String topic,
    MessageContent content, {
    Json? head,
  });

  /// Deletes messages for this user, or with [hard] for everyone; returns
  /// the delete ID.
  Future<int> deleteMessages(
    String topic,
    List<SeqRange> ranges, {
    required bool hard,
  });

  /// The deletions with delete IDs from [since] on.
  Future<DeleteLog> deleteLog(String topic, {int? since, int? limit});

  void sendTyping(String topic);

  void markRead(String topic, int seq);

  /// The server's reply to the latest `hi`, with its ICE servers for calls.
  ServerInfo get serverInfo;

  /// Calls the peer of the 1:1 [topic]; the result's seq names the call.
  Future<PublishResult> startCall(String topic, {required bool audioOnly});

  /// Sends one step of call [seq]. Throws `ConnectionClosedException`
  /// while not connected, rather than dropping it.
  void sendCallEvent(String topic, int seq, CallEvent event, {Json? payload});

  Stream<DataMessage> get messages;

  Stream<PresMessage> get presence;

  Stream<InfoMessage> get info;

  /// Where the link to the server stands now.
  ConnectionStatus get status;

  /// Changes of the link to the server. After a drop the client restores
  /// the login and attached topics; `Connected` then means catch up.
  Stream<ConnectionStatus> get statusChanges;

  /// Closes the socket on purpose, e.g. in the background.
  void suspend();

  /// Reconnects at once after [suspend] or during a backoff wait; on a live
  /// link it probes the socket instead, within [probeTimeout] if given.
  void resume({Duration? probeTimeout});

  Future<void> close();
}
