import 'package:tinode_dart_client/tinode_dart_client.dart';

/// Opens a [TinodeSession] to the server described by a [TinodeConfig].
typedef SessionConnector = Future<TinodeSession> Function(TinodeConfig config);

/// One connection to a Tinode server, as the rest of the package sees it.
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

  /// Up to [limit] messages before [before] (or the newest), oldest first.
  Future<List<DataMessage>> history(
    String topic, {
    required int limit,
    int? before,
  });

  Future<PublishResult> publish(String topic, MessageContent content);

  void sendTyping(String topic);

  void markRead(String topic, int seq);

  Stream<DataMessage> get messages;

  Stream<PresMessage> get presence;

  Stream<InfoMessage> get info;

  /// Completes when the connection ends, for any reason.
  Future<void> get closed;

  Future<void> close();
}
