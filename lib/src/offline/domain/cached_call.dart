import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A call message the cache holds, with the server's updates of it
/// (`head.replace`: the call's later states), oldest first.
final class CachedCall with ValueObject {
  const CachedCall(this.message, [this.updates = const []]);

  final DataMessage message;
  final List<DataMessage> updates;

  @override
  List<Object?> get props => [message, updates];
}
