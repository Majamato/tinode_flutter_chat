import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/message_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/progress_throttle.dart';
import 'package:tinode_flutter_chat/src/chats/domain/chat_message.dart';

import '../../support/fixtures.dart';

void main() {
  group('MessageAttachment', () {
    test('reads TinodeWeb images and files, images first', () {
      final content = DraftyContent(
        Drafty.fromJson(const {
          'txt': '  Look!',
          'fmt': [
            {'at': -1, 'key': 1},
            {'len': 1},
            {'at': 1, 'len': 1, 'tp': 'BR'},
          ],
          'ent': [
            {
              'tp': 'IM',
              'data': {
                'mime': 'image/jpeg',
                'ref': '/v0/file/s/a.jpg',
                'width': 640,
                'height': 480,
              },
            },
            {
              'tp': 'EX',
              'data': {'name': 'a.pdf', 'ref': '/v0/file/s/a.pdf', 'size': 9},
            },
          ],
        }),
      );

      final received = ChatMessage.fromData(
        DataMessage(topic: bob, seq: 1, time: at(1), content: content),
        me: alice,
      );

      expect(received.attachments, [
        const ImageAttachment(
          ref: '/v0/file/s/a.jpg',
          mimeType: 'image/jpeg',
          width: 640,
          height: 480,
        ),
        const FileAttachment(ref: '/v0/file/s/a.pdf', name: 'a.pdf', size: 9),
      ]);
      expect(received.caption, 'Look!');
      expect(
        (received.attachments.first as ImageAttachment).aspectRatio,
        640 / 480,
      );
    });

    test('inline images carry their bytes; empty entities are skipped', () {
      final attachments = MessageAttachment.listFrom(
        DraftyContent(
          Drafty.fromJson(const {
            'txt': '  ',
            'fmt': [
              {'len': 1},
              {'at': 1, 'len': 1, 'key': 1},
            ],
            'ent': [
              {
                'tp': 'IM',
                'data': {'val': 'AQID'},
              },
              {'tp': 'IM', 'data': <String, Object?>{}},
            ],
          }),
        ),
      );

      expect(attachments, hasLength(1));
      final image = attachments.single as ImageAttachment;
      expect(image.bytes, [1, 2, 3]);
      expect(image.aspectRatio, ImageAttachment.defaultAspectRatio);
    });

    test('plain text has none and keeps its text as caption', () {
      final text = ChatMessage.fromData(message(bob, 1), me: alice);
      expect(text.attachments, isEmpty);
      expect(text.caption, 'message 1');
    });
  });

  group('OutgoingAttachment', () {
    const attachment = OutgoingAttachment(
      stagedId: '1_a.png',
      name: 'a.png',
      size: 30,
      mimeType: 'image/png',
      isImage: true,
      width: 3,
      height: 2,
      caption: 'hi',
    );

    test('round-trips through JSON', () {
      final uploaded = attachment.uploaded('/v0/file/s/x.png', at(5));
      expect(OutgoingAttachment.fromJson(uploaded.toJson()), uploaded);
      expect(OutgoingAttachment.fromJson(attachment.toJson()), attachment);
    });

    test('needs an upload until it has a ref that is not about to expire', () {
      expect(attachment.needsUpload(at(0)), isTrue);
      final uploaded = attachment.uploaded('r', at(1));
      expect(uploaded.needsUpload(at(0)), isFalse);
      expect(
        uploaded.needsUpload(at(1).subtract(const Duration(seconds: 3))),
        isTrue,
      );
    });

    test('its content is the image above the caption, with the ref', () {
      final drafty = attachment.uploaded('r', at(1)).content.drafty;
      expect(drafty.images.single.ref, 'r');
      expect(drafty.images.single.width, 3);
      expect(drafty.caption, 'hi');

      const file = OutgoingAttachment(stagedId: 's', name: 'a.pdf', size: 1);
      expect(file.content.drafty.files.single.name, 'a.pdf');
    });
  });

  group('ProgressThrottle', () {
    test('passes the first, the last, and at most one per interval', () {
      final throttle = ProgressThrottle();
      final start = at(0);
      Duration ms(int value) => Duration(milliseconds: value);

      expect(throttle.admit(1, 1000, start), isTrue);
      expect(throttle.admit(50, 1000, start.add(ms(10))), isFalse);
      expect(throttle.admit(60, 1000, start.add(ms(120))), isTrue);
      // A step under 1 % waits, however long it took.
      expect(throttle.admit(65, 1000, start.add(ms(500))), isFalse);
      expect(throttle.admit(1000, 1000, start.add(ms(510))), isTrue);
    });
  });
}
