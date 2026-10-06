import 'package:tinode_dart_client/tinode_dart_client.dart';

/// Opens a [TinodeSession] to the server described by a [TinodeConfig].
typedef SessionConnector = Future<TinodeSession> Function(TinodeConfig config);

/// The link to a Tinode server, as the rest of the package sees it.
///
/// It wraps `TinodeClient` (a final class that cannot be faked) so that
/// tests can swap in a fake, and so a cached or offline session can slot
/// in later. Names follow the glossary: a session *attaches* to a topic.
abstract interface class TinodeSession {
  Future<LoginResult> loginBasic(String login, String password);

  Future<LoginResult> loginToken(String token);

  /// Starts receiving the topic's live traffic; returns its real name.
  Future<String> attach(String topic);

  /// Stops receiving the topic's live traffic; the subscription stays.
  Future<void> detach(String topic);

  /// The chat list: the subscriptions of `me` that name a topic.
  Future<List<Subscription>> chatList();

  /// Up to [limit] messages with `since <= seq < before`, the newest of
  /// them, oldest first.
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? since,
    int? before,
  });

  Future<PublishResult> publish(String topic, MessageContent content);

  void sendTyping(String topic);

  void markRead(String topic, int seq);

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
