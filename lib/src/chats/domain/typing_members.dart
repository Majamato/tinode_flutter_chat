import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The members typing in a chat right now, by name, first to start first.
/// A null name is a member not known yet.
final class TypingMembers with ValueObject {
  const TypingMembers({this.names = const [], this.direct = false});

  final List<String?> names;

  /// In a direct chat, where only the peer can be typing.
  final bool direct;

  bool get isEmpty => names.isEmpty;

  @override
  List<Object?> get props => [names, direct];
}
