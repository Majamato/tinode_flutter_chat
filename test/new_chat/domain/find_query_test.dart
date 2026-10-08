import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/new_chat/domain/find_query.dart';

void main() {
  test('a word is looked up as a tag and as a login', () {
    expect(findQuery('Bob'), 'bob,basic:bob');
  });

  test('words may match on their own', () {
    expect(findQuery(' bob,  carol '), 'bob,basic:bob,carol,basic:carol');
  });

  test('emails, phones and prefixed tags go as typed', () {
    expect(
      findQuery('bob@example.com +1702-555 tel:123 email:x@y.z'),
      'bob@example.com,+1702-555,tel:123,email:x@y.z',
    );
  });

  test('a repeated word is searched once', () {
    expect(findQuery('bob Bob'), 'bob,basic:bob');
  });

  test('input too short is not searched', () {
    expect(findQuery(''), isNull);
    expect(findQuery(' b , '), isNull);
    expect(findQuery('bo'), isNotNull);
  });
}
