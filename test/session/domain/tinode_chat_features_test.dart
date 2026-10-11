import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  test('automatic offers the reset only where email is required', () {
    const features = TinodeChatFeatures();
    expect(features.signUp, isTrue);
    expect(features.offersPasswordReset(const ['email']), isTrue);
    expect(features.offersPasswordReset(const []), isFalse);
    expect(features.offersPasswordReset(const ['tel']), isFalse);
  });

  test('always and never ignore the server', () {
    const always = TinodeChatFeatures(passwordReset: PasswordResetMode.always);
    const never = TinodeChatFeatures(passwordReset: PasswordResetMode.never);
    expect(always.offersPasswordReset(const []), isTrue);
    expect(never.offersPasswordReset(const ['email']), isFalse);
  });
}
