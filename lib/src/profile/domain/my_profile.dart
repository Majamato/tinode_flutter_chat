import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/avatar_image.dart';
import 'package:tinode_flutter_chat/src/shared/domain/initials.dart';
import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// The user's own profile, as others see it: the `public` of `me`.
final class MyProfile with ValueObject {
  const MyProfile(this.profile);

  /// The whole profile, other theCard fields included, to edit it from.
  final Profile profile;

  String get name => profile.name?.trim() ?? '';

  String get note => profile.note?.trim() ?? '';

  AvatarImage? get photo => AvatarImage.tryParse(profile.photo);

  /// Up to two letters for the avatar; see [initialsOf].
  String get initials => initialsOf(name);

  /// The image subtype a profile photo of [mimeType] is marked with, e.g.
  /// `jpeg` for `image/jpeg`.
  static String? photoType(String? mimeType) => switch (mimeType?.split('/')) {
    [_, final subtype] when subtype.isNotEmpty => subtype,
    _ => null,
  };

  @override
  List<Object?> get props => [profile];
}
