import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The system's ID of call [seq] in [topic]: a UUID, as CallKit wants, the
/// same wherever it is made, so the app and a push handler name one call
/// alike.
String systemCallId(String topic, int seq) {
  final bytes = sha1
      .convert(utf8.encode('tinode_flutter_chat/call/$topic/$seq'))
      .bytes
      .sublist(0, 16);
  // A name-based UUID (version 5, RFC 4122 variant).
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [
    for (final b in bytes) b.toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
