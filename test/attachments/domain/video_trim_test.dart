import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/outgoing_attachment.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/tinode_attachment_limits.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/video_trim.dart';

void main() {
  Duration s(int seconds) => Duration(seconds: seconds);

  final total = s(100);
  final maxLength = s(40);

  group('VideoTrim', () {
    test('starts with as much as can be sent, from the beginning', () {
      expect(VideoTrim.initial(total, maxLength), VideoTrim(s(0), s(40)));
      expect(VideoTrim.initial(s(10), maxLength), VideoTrim(s(0), s(10)));
    });

    test('knows when it is the whole video', () {
      expect(VideoTrim(s(0), s(100)).coversAll(total), isTrue);
      expect(VideoTrim(s(1), s(100)).coversAll(total), isFalse);
      expect(VideoTrim(s(0), s(99)).coversAll(total), isFalse);
    });

    group('moving its start', () {
      final trim = VideoTrim(s(30), s(60));

      test('follows the handle', () {
        expect(
          trim.withStart(s(25), total: total, maxLength: maxLength),
          VideoTrim(s(25), s(60)),
        );
      });

      test('stops at the maximum', () {
        expect(
          trim.withStart(s(0), total: total, maxLength: maxLength),
          VideoTrim(s(20), s(60)),
        );
      });

      test('stops at the minimum', () {
        expect(
          trim.withStart(s(90), total: total, maxLength: maxLength),
          VideoTrim(s(59), s(60)),
        );
      });

      test('stops at the beginning', () {
        expect(
          VideoTrim(
            s(10),
            s(20),
          ).withStart(-s(5), total: total, maxLength: maxLength),
          VideoTrim(s(0), s(20)),
        );
      });
    });

    group('moving its end', () {
      final trim = VideoTrim(s(30), s(60));

      test('follows the handle', () {
        expect(
          trim.withEnd(s(65), total: total, maxLength: maxLength),
          VideoTrim(s(30), s(65)),
        );
      });

      test('stops at the maximum', () {
        expect(
          trim.withEnd(s(100), total: total, maxLength: maxLength),
          VideoTrim(s(30), s(70)),
        );
      });

      test('stops at the minimum', () {
        expect(
          trim.withEnd(s(0), total: total, maxLength: maxLength),
          VideoTrim(s(30), s(31)),
        );
      });

      test('stops at the end of the video', () {
        expect(
          VideoTrim(
            s(80),
            s(90),
          ).withEnd(s(200), total: total, maxLength: maxLength),
          VideoTrim(s(80), s(100)),
        );
      });
    });

    group('moving the whole of it', () {
      final trim = VideoTrim(s(30), s(60));

      test('keeps its length', () {
        expect(trim.movedTo(s(50), total: total), VideoTrim(s(50), s(80)));
      });

      test('stops at both ends of the video', () {
        expect(trim.movedTo(-s(5), total: total), VideoTrim(s(0), s(30)));
        expect(trim.movedTo(s(90), total: total), VideoTrim(s(70), s(100)));
      });
    });

    test('a video shorter than the minimum can still be chosen whole', () {
      const short = Duration(milliseconds: 500);
      final trim = VideoTrim.initial(short, maxLength);

      expect(
        trim.withEnd(Duration.zero, total: short, maxLength: maxLength),
        trim,
      );
    });
  });

  group('TinodeAttachmentLimits', () {
    const limits = TinodeAttachmentLimits();
    const mib = 1024 * 1024;

    test('all of a video within the limit can be sent, however long', () {
      expect(limits.maxClip(fileBytes: 15 * mib, duration: s(300)), s(300));
    });

    test('all of a video that will fit once compressed can be sent', () {
      expect(limits.maxClip(fileBytes: 100 * mib, duration: s(60)), s(60));
    });

    test('of a long and large video, as much as fits', () {
      expect(
        limits.maxClip(fileBytes: 200 * mib, duration: s(600)),
        limits.maxVideoDuration,
      );
    });

    test('of a large video a little longer than fits, as much as fits', () {
      // Within the limit at the bitrates asked, but not with the encoder's
      // headroom.
      expect(
        limits.maxClip(fileBytes: 125 * mib, duration: s(97)),
        limits.maxVideoDuration,
      );
    });

    test('a lower server limit makes the part shorter', () {
      expect(
        limits.maxClip(
          fileBytes: 200 * mib,
          duration: s(600),
          serverLimit: 10 * mib,
        ),
        limits.maxVideoDurationFor(10 * mib),
      );
    });

    test('a trimmed video keeps the bitrate of a poorer source', () {
      // 15 MB over 5 minutes: 400 kbit/s, 272 of them for the picture.
      expect(limits.trimmedVideoBitrate(15000000, s(300)), 272000);
    });

    test('a trimmed video gets no more than the usual bitrate', () {
      expect(limits.trimmedVideoBitrate(200 * mib, s(60)), limits.videoBitrate);
    });

    test('a trimmed video keeps a working bitrate', () {
      expect(limits.trimmedVideoBitrate(1000, s(600)), 100000);
      expect(limits.trimmedVideoBitrate(1000, Duration.zero), 1500000);
    });

    group('a second pass', () {
      const limit = 20 * mib;

      int secondPass(int outputBytes, {Duration? duration}) =>
          limits.secondPassVideoBitrate(
            asked: limits.videoBitrate,
            outputBytes: outputBytes,
            duration: duration ?? s(90),
            limitBytes: limit,
          );

      test('asks less by as much as the encoder overshot', () {
        // An encoder that turned 1.5 Mbit/s into 2.49: 90 s came out at
        // about 29.5 MB. 20 MiB with headroom over 90 s leaves 1.55 Mbit/s
        // for the picture.
        expect(secondPass(29452500), 933567);
      });

      test('then fits the limit, if the encoder overshoots alike', () {
        final asked = secondPass(29452500);
        final bytes =
            (asked * 2490000 / 1500000 + limits.audioBitrate) * 90 / 8;

        expect(bytes, lessThan(limit));
      });

      test('never asks more than the first', () {
        // An encoder that undershot: 10 MiB over 90 s.
        expect(secondPass(10 * mib), limits.videoBitrate);
      });

      test('keeps a working bitrate', () {
        expect(secondPass(1 << 40), 100000);
        expect(secondPass(29452500, duration: Duration.zero), 1500000);
      });
    });
  });

  group('OutgoingAttachment', () {
    const attachment = OutgoingAttachment(
      stagedId: 's',
      name: 'clip.mov',
      size: 10,
      isVideo: true,
      duration: Duration(seconds: 100),
    );

    test('trimmed plays only its part, still to compress', () {
      final trimmed = attachment.trimmed(VideoTrim(s(10), s(40)));

      expect(trimmed.trim, VideoTrim(s(10), s(40)));
      expect(trimmed.duration, s(30));
      expect(trimmed.pendingCompression, isTrue);
    });

    test('remembers its part when stored', () {
      final trimmed = attachment.trimmed(VideoTrim(s(10), s(40)));

      expect(OutgoingAttachment.fromJson(trimmed.toJson()), trimmed);
      expect(OutgoingAttachment.fromJson(attachment.toJson()).trim, isNull);
    });

    test('the compressed copy is already cut', () {
      final compressed = attachment
          .trimmed(VideoTrim(s(10), s(40)))
          .compressed(
            stagedId: 't',
            name: 'clip.mp4',
            size: 5,
            mimeType: 'video/mp4',
          );

      expect(compressed.trim, isNull);
      expect(compressed.duration, s(30));
      expect(compressed.pendingCompression, isFalse);
    });
  });
}
