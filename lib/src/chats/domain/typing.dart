import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Typing in one chat: the user IDs of the members typing now, first to
/// start first, and how the last one to stop stopped.
final class Typing with ValueObject {
  const Typing({this.userIds = const [], this.endedWithMessage = false});

  final List<String> userIds;

  /// Whether the last member to stop typing stopped because their message
  /// arrived, rather than after a pause.
  final bool endedWithMessage;

  bool get isEmpty => userIds.isEmpty;

  /// With [userId] typing too, after the others.
  Typing started(String userId) => Typing(
    userIds: List.unmodifiable([...userIds, userId]),
    endedWithMessage: endedWithMessage,
  );

  /// Without [userId], who stopped [withMessage] or after a pause.
  Typing stopped(String userId, {required bool withMessage}) => Typing(
    userIds: List.unmodifiable(userIds.where((id) => id != userId)),
    endedWithMessage: withMessage,
  );

  @override
  List<Object?> get props => [userIds, endedWithMessage];
}
