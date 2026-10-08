import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// A group the user created: its name, and the members it could not add.
final class NewGroup with ValueObject {
  const NewGroup({required this.topic, this.notAdded = const []});

  /// The group's `grp…` name.
  final String topic;

  /// The titles of the members the server refused to add.
  final List<String> notAdded;

  @override
  List<Object?> get props => [topic, notAdded];
}
