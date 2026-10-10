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

  /// The members of [topic], with their profiles and read and received
  /// counters; with [userId], just that member, or `[]` when they aren't
  /// one. The topic must be attached. In a direct chat they come without
  /// profiles.
  Future<List<Subscription>> members(String topic, {String? userId});

  /// Users and groups whose tags match [query], best first; see
  /// `TinodeClient.find`. A user's result is named by their user ID,
  /// which [attach] opens as the 1:1 chat with them.
  Future<List<FoundTopic>> find(String query);

  /// Creates a group named in [public], with this user as its owner, and
  /// returns its `grp…` name. The new group is attached as by [attach]:
  /// release it with [detach].
  Future<String> createGroup({required Profile public});

  /// Adds the user [userId] to the group [topic] with the group's default
  /// access. Needs the `S` permission.
  Future<void> addMember(String topic, String userId);

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

  /// Tells the other members this device received [topic] up to [seq].
  /// Works for a topic that isn't attached too. Dropped while not
  /// connected.
  void markReceived(String topic, int seq);

  /// The server's reply to the latest `hi`, with its ICE servers for calls.
  ServerInfo get serverInfo;

  /// Uploads a file for a message; see `TinodeClient.upload`. Needs a
  /// login but not a live link: without one it throws [StateError].
  Future<UploadResult> upload(
    Stream<List<int>> Function() openRead, {
    required int length,
    required String filename,
    String? mimeType,
    void Function(int sent, int total)? onProgress,
    Future<void>? abortTrigger,
  });

  /// Fetches the file [ref] names; see `TinodeClient.download`.
  Future<FileDownload> download(String ref, {Future<void>? abortTrigger});

  /// The URL of the file [ref] names; null for refs that aren't http(s).
  Uri? resolveFile(String ref);

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
