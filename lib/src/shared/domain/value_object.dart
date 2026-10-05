import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

const _equality = DeepCollectionEquality();

/// Value equality over [props]. Riverpod skips notifying listeners when a
/// new state is `==` to the old one, so states built from these stay quiet
/// when nothing changed.
@immutable
mixin ValueObject {
  @protected
  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueObject &&
          other.runtimeType == runtimeType &&
          _equality.equals(props, other.props);

  @override
  int get hashCode => _equality.hash(props);

  @override
  String toString() => '$runtimeType(${props.join(', ')})';
}
