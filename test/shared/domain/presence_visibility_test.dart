import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/shared/domain/presence_visibility.dart';

void main() {
  test('a profile hides presence only with x-presence: hidden', () {
    expect(const Profile(name: 'Bob').hidesPresence, isFalse);
    expect(const Profile(raw: {'x-presence': 'shown'}).hidesPresence, isFalse);
    expect(
      Profile.fromJson(const {
        'fn': 'Bob',
        'x-presence': 'hidden',
      }).hidesPresence,
      isTrue,
    );
  });

  test('hiding and showing keep the rest of the profile', () {
    final profile = Profile.fromJson(const {
      'fn': 'Alice',
      'note': 'hi',
      'photo': {'type': 'jpg', 'ref': '/v0/file/s/a.jpg'},
      'org': 'Acme',
    });

    final hidden = profile.withPresenceHidden(hidden: true);
    expect(hidden.toJson(), {
      'fn': 'Alice',
      'note': 'hi',
      'photo': {'type': 'jpg', 'ref': '/v0/file/s/a.jpg'},
      'org': 'Acme',
      'x-presence': 'hidden',
    });
    expect(hidden.hidesPresence, isTrue);

    final shown = hidden.withPresenceHidden(hidden: false);
    expect(shown.toJson(), profile.toJson());
    expect(shown.hidesPresence, isFalse);
  });

  test('an edit after hiding keeps it hidden', () {
    final hidden = const Profile(
      name: 'Alice',
    ).withPresenceHidden(hidden: true);
    expect(hidden.copyWith(name: 'Ali').hidesPresence, isTrue);
  });
}
