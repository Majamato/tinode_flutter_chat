@Tags(['smtp'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/app/application/tinode_container.dart';
import 'package:tinode_flutter_chat/src/offline/data/chat_store_opener.dart';
import 'package:tinode_flutter_chat/src/session/application/confirm_email_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_controller.dart';
import 'package:tinode_flutter_chat/src/session/application/session_state.dart';
import 'package:tinode_flutter_chat/src/session/application/sign_up_controller.dart';

import 'account_test.dart' show uniqueLogin;
import 'group_chat_test.dart' show config;

// Needs ../tinode-tests with its mail override, whose server requires an
// email at sign-up and mails the code to Mailpit:
//   docker compose -f docker-compose.yml -f docker-compose.mail.yml up -d
//   flutter test --tags smtp --run-skipped

/// The code in the newest email Mailpit caught for [to].
Future<String> mailedCode(String to) async {
  final client = HttpClient();
  addTearDown(client.close);
  Future<Object?> get(String path) async {
    final request = await client.getUrl(
      Uri.parse('http://localhost:8025/api/v1/$path'),
    );
    final response = await request.close();
    return jsonDecode(await response.transform(utf8.decoder).join());
  }

  for (var attempt = 0; attempt < 50; attempt++) {
    final search = await get(
      'search?query=${Uri.encodeQueryComponent('to:$to')}',
    );
    final messages = (search! as Map)['messages'];
    if (messages case [final Map<String, Object?> first, ...]) {
      final message = await get('message/${first['ID']}');
      final text = (message! as Map)['Text']! as String;
      return RegExp(r'following code:\s*(\d+)').firstMatch(text)!.group(1)!;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('no email to $to');
}

void main() {
  test('a sign-up confirms its email, then logs in', () async {
    final container = createTinodeContainer(
      config: config,
      storeOpener: MemoryChatStoreOpener(),
    );
    addTearDown(container.dispose);
    container
      ..listen(sessionControllerProvider, (_, _) {})
      ..listen(signUpControllerProvider, (_, _) {})
      ..listen(confirmEmailControllerProvider, (_, _) {});
    await container.read(sessionControllerProvider.future);
    expect(container.read(signUpNeedsEmailProvider), isTrue);

    final login = uniqueLogin('pe');
    final email = '$login@example.com';
    final confirm = await container
        .read(signUpControllerProvider.notifier)
        .submit(login: login, password: 'secret1', name: 'Probe', email: email);
    expect(confirm, isTrue);

    await container
        .read(confirmEmailControllerProvider.notifier)
        .confirm(
          login: login,
          password: 'secret1',
          code: await mailedCode(email),
        );
    expect(
      container.read(sessionControllerProvider).value,
      isA<SessionLoggedIn>(),
    );

    await container.read(sessionControllerProvider.notifier).deleteAccount();
  });
}
