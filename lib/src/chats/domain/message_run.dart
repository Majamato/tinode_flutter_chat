import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Where a message sits among its neighbours, as its bubble shows it:
/// the gap above it, its tail, and a date above it.
final class MessageRun with ValueObject {
  const MessageRun({
    required this.startsRun,
    required this.endsRun,
    required this.startsDay,
  });

  /// A message whose neighbours aren't known: a run of its own.
  static const alone = MessageRun(
    startsRun: true,
    endsRun: true,
    startsDay: false,
  );

  /// The first message of a run: messages from one sender in a row, each
  /// close to the one before.
  final bool startsRun;

  /// The last message of a run; its bubble has the tail.
  final bool endsRun;

  /// The first message of its day; a date shows above it.
  final bool startsDay;

  @override
  List<Object?> get props => [startsRun, endsRun, startsDay];
}
