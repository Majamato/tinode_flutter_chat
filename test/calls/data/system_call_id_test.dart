import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/calls/data/system_call_id.dart';

void main() {
  test('names a call the same wherever it is made', () {
    expect(systemCallId('usrBob', 4), systemCallId('usrBob', 4));
    expect(systemCallId('usrBob', 4), isNot(systemCallId('usrBob', 5)));
    expect(systemCallId('usrBob', 4), isNot(systemCallId('usrCarol', 4)));
  });

  test('is a version 5 UUID', () {
    expect(
      systemCallId('usrBob', 4),
      matches(
        RegExp(
          '^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
