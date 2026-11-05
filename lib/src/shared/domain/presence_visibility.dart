import 'package:tinode_dart_client/tinode_dart_client.dart';

/// Where a user's `public` says they hide their presence: a custom theCard
/// key, which the server keeps and sends to everyone who sees the profile.
const presenceVisibilityKey = 'x-presence';

/// The value of [presenceVisibilityKey] for a user who hides their presence.
const presenceHiddenValue = 'hidden';

/// The value of [presenceVisibilityKey] for a user who shows it again. The
/// server merges `public` key by key, so leaving the key out would keep
/// [presenceHiddenValue]; any value but that one reads as shown.
const presenceShownValue = 'shown';

/// Whether a user hides their presence, i.e. asks not to be shown online or
/// with a last seen. Only apps that read this key honour it: the server
/// still sends their presence, and other Tinode clients may show it.
extension PresenceVisibility on Profile {
  /// The user asked others not to see when they are online or were last
  /// seen.
  bool get hidesPresence => raw[presenceVisibilityKey] == presenceHiddenValue;

  /// This profile asking to hide presence, or not: [presenceVisibilityKey]
  /// is always written, since the server keeps a key left out. Everything
  /// else in it, other theCard fields included, stays.
  Profile withPresenceHidden({required bool hidden}) => Profile(
    name: name,
    note: note,
    photo: photo,
    raw: {
      for (final MapEntry(:key, :value) in raw.entries)
        if (!const {'fn', 'note', 'photo', presenceVisibilityKey}.contains(key))
          key: value,
      presenceVisibilityKey: hidden ? presenceHiddenValue : presenceShownValue,
    },
  );
}
