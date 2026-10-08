import 'dart:convert';
import 'dart:math';

import 'package:tinode_dart_client/tinode_dart_client.dart';

/// The `head` key that carries a message's client ID. Tinode has no
/// idempotency key, so after a drop the outbox looks for this ID on the
/// server before sending a message again.
const clientIdHeadKey = 'x-tinode-flutter-chat-cid';

final _random = Random.secure();

/// A new client ID: 128 random bits, base64url without padding.
String newClientId() => base64Url
    .encode(List.generate(16, (_) => _random.nextInt(256)))
    .replaceAll('=', '');

/// The client ID in [head], if the message was sent by this package.
String? clientIdOf(MessageHead? head) => switch (head?.raw[clientIdHeadKey]) {
  final String id => id,
  _ => null,
};
