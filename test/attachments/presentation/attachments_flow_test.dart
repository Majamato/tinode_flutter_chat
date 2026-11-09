import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/compressed_media.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/local_file.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/attachment_preview_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_bubble_content.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/image_viewer_screen.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/outgoing_attachment_view.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/stand_in_picture.dart';
import 'package:tinode_flutter_chat/src/attachments/presentation/video_bubble_content.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/ref_photo_avatar.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/back_button.dart';
import '../../support/fake_attachment_picker.dart';
import '../../support/fake_media_compressor.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const icons = TinodeChatIcons();

const reportRef = '/v0/file/s/report.pdf';

DataMessage fileMessage(int seq) => DataMessage(
  topic: bob,
  seq: seq,
  from: bob,
  time: at(seq),
  head: const MessageHead(mime: MessageHead.draftyMime),
  content: DraftyContent(
    Drafty.file(
      const DraftyFile(
        name: 'report.pdf',
        mimeType: 'application/pdf',
        size: 2048,
        ref: reportRef,
      ),
      caption: 'The report',
    ),
  ),
);

void main() {
  late FakeTinodeSession session;
  late FakeAttachmentPicker picker;
  late FakeMediaCompressor compressor;
  late List<LocalFile> opened;
  late bool openWorks;

  setUp(() {
    session = FakeTinodeSession(
      chats: [
        chat(bob, name: 'Bob', lastSeq: 1, read: 1, lastMessageAt: at(1)),
      ],
      histories: {
        bob: [fileMessage(1)],
      },
    );
    session.files[reportRef] = pngBytes;
    picker = FakeAttachmentPicker();
    compressor = FakeMediaCompressor(poster: pngBytes);
    opened = [];
    openWorks = true;
  });

  Future<void> openBob(WidgetTester tester) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      attachmentPicker: picker,
      mediaCompressor: compressor,
      fileOpener: (file, {mimeType}) async {
        opened.add(file);
        return openWorks;
      },
    );
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseFromMenu(WidgetTester tester, String entry) async {
    await tester.tap(find.byIcon(icons.attach));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  testWidgets('sends a photo with a caption, then shows and opens it', (
    tester,
  ) async {
    await openBob(tester);
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );

    await chooseFromMenu(tester, 'Gallery');
    expect(picker.picks, [AttachmentSource.media]);
    expect(find.byType(AttachmentPreviewScreen), findsOneWidget);
    expect(backText(), findsNothing);

    await tester.enterText(find.byType(TextField), 'Sunset');
    await tester.tap(find.byIcon(icons.send));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentPreviewScreen), findsNothing);
    expect(
      session.calls,
      // Compressed to a JPEG first.
      containsAllInOrder(['upload sunset.jpg', 'publish $bob   Sunset']),
    );
    expect(find.byType(ImageBubbleContent), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    // Sent from here: shown from the cache, never downloaded.
    expect(session.calls, isNot(contains(startsWith('download'))));

    await tester.tap(find.byType(ImageBubbleContent));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewerScreen), findsOneWidget);
    expect(backText(), findsNothing);
    // Always black, so the status bar's icons stay light in a light theme.
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.descendant(
              of: find.byType(ImageViewerScreen),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            ),
          )
          .value
          .statusBarIconBrightness,
      Brightness.light,
    );

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewerScreen), findsNothing);
  });

  testWidgets('back from the preview sends nothing', (tester) async {
    await openBob(tester);
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Gallery');

    await tester.tap(backButton());
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentPreviewScreen), findsNothing);
    expect(session.calls, isNot(contains(startsWith('upload'))));
  });

  testWidgets('a picker that fails twice says so twice', (tester) async {
    await openBob(tester);
    picker.failWith = PlatformException(code: 'picker_broken');

    await chooseFromMenu(tester, 'Gallery');
    expect(find.byType(SnackBar), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(SnackBar)),
    ).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    await chooseFromMenu(tester, 'Gallery');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(picker.picks, [AttachmentSource.media, AttachmentSource.media]);
    expect(find.byType(AttachmentPreviewScreen), findsNothing);
  });

  testWidgets('a received file downloads and opens on tap', (tester) async {
    await openBob(tester);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('2 KB'), findsOneWidget);
    expect(find.text('The report'), findsOneWidget);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(session.calls, contains('download $reportRef'));
    expect(opened.single.length, pngBytes.length);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a file nothing opens says so', (tester) async {
    openWorks = false;
    await openBob(tester);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('No app on this device opens this file.'), findsOneWidget);
  });

  testWidgets('a failed download says so', (tester) async {
    session.failDownload = const ServerException(404, 'not found');
    await openBob(tester);

    await tester.tap(find.text('report.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('The file could not be downloaded.'), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('without a camera the menu offers none', (tester) async {
    picker.hasCamera = false;
    await openBob(tester);

    await tester.tap(find.byIcon(icons.attach));
    await tester.pumpAndSettle();

    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Camera'), findsNothing);
  });

  testWidgets('a file over the limit is refused, naming the limit', (
    tester,
  ) async {
    session.serverInfo = const ServerInfo(
      version: '0.25',
      maxFileUploadSize: 4,
    );
    await openBob(tester);
    picker.next = pickedText('notes.txt', 'hello');

    await chooseFromMenu(tester, 'File');
    await tester.tap(find.byIcon(icons.send));
    await tester.pumpAndSettle();

    expect(
      find.text('The file is too large to send: the limit is 4 B.'),
      findsOneWidget,
    );
    expect(session.calls, isNot(contains(startsWith('upload'))));
  });

  testWidgets('upload progress rebuilds only the ring', (tester) async {
    await openBob(tester);
    final steps = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'big.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(OutgoingAttachmentView), findsOneWidget);

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, _) =>
        rebuilt.add(element.widget.runtimeType.toString());
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    for (final sent in [10, 30, 50]) {
      steps.add(sent);
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(rebuilt, contains('AttachmentProgressRing'));
    expect(
      rebuilt.where((w) => w.contains('Bubble') || w.contains('Message')),
      isEmpty,
    );

    debugOnRebuildDirtyWidget = null;
    await steps.close();
    await tester.pumpAndSettle();
    expect(find.byType(ImageBubbleContent), findsOneWidget);
  });

  /// The picture [of] draws, under its progress, if any.
  ImageProvider<Object>? pictureIn(WidgetTester tester, Finder of) {
    final images = find.descendant(of: of, matching: find.byType(Image));
    if (images.evaluate().isEmpty) {
      return null;
    }
    return switch (tester.widget<Image>(images.last).image) {
      ResizeImage(:final imageProvider) => imageProvider,
      final image => image,
    };
  }

  /// The stand-in under [of]'s picture.
  LocalFile? standInIn(WidgetTester tester, Finder of) => tester
      .widget<StandInPicture>(
        find.descendant(of: of, matching: find.byType(StandInPicture)),
      )
      .standIn;

  testWidgets('a photo shows its poster at once, all the way to sent', (
    tester,
  ) async {
    await openBob(tester);
    final poster = Uint8List.fromList(pngBytes);
    compressor.imagePosterBytes = poster;
    final uploading = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Compressed by now: the staged copy changed, the picture didn't.
    final outgoing = find.byType(OutgoingAttachmentView);
    expect(find.text('Uploading…'), findsOneWidget);
    expect(
      pictureIn(tester, outgoing),
      isA<MemoryImage>().having((i) => i.bytes, 'bytes', poster),
    );

    await uploading.close();
    await tester.pumpAndSettle();
    final sent = find.byType(ImageBubbleContent);
    expect(sent, findsOneWidget);
    expect(standInIn(tester, sent)?.bytes, poster);
  });

  testWidgets("a photo's stand-in is there when the echo beats the ack", (
    tester,
  ) async {
    await openBob(tester);
    final poster = Uint8List.fromList(pngBytes);
    compressor.imagePosterBytes = poster;
    final ack = session.holdAck = Completer<void>();
    final uploading = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OutgoingAttachmentView), findsOneWidget);

    await uploading.close();
    // The echo has replaced the outgoing bubble; the ack hasn't come.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(ack.isCompleted, isFalse);
    final sent = find.byType(ImageBubbleContent);
    expect(sent, findsOneWidget);
    expect(standInIn(tester, sent)?.bytes, poster);

    ack.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ImageBubbleContent), findsOneWidget);
  });

  testWidgets('a photo without a poster keeps its picture once shown', (
    tester,
  ) async {
    await openBob(tester);
    final uploading = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'sunset.png',
      pngBytes,
      mimeType: 'image/png',
      isImage: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));

    // Frame by frame through the compression's swap of the staged copy.
    var shown = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final outgoing = find.byType(OutgoingAttachmentView);
      if (outgoing.evaluate().isEmpty) {
        continue;
      }
      final picture = pictureIn(tester, outgoing);
      if (shown) {
        expect(picture, isNotNull, reason: 'frame $i');
      }
      shown |= picture != null;
    }
    expect(shown, isTrue);
    expect(find.text('Uploading…'), findsOneWidget);

    await uploading.close();
    await tester.pumpAndSettle();
    expect(standInIn(tester, find.byType(ImageBubbleContent)), isNotNull);
  });

  testWidgets('a sent video shows its outgoing poster under its own', (
    tester,
  ) async {
    await openBob(tester);
    picker.next = pickedFile(
      'clip.mov',
      List.filled(100, 1),
      mimeType: 'video/quicktime',
      isVideo: true,
    );
    final uploading = session.uploadSteps = StreamController<int>();
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OutgoingAttachmentView), findsOneWidget);

    await uploading.close();
    await tester.pumpAndSettle();
    final sent = find.byType(VideoBubbleContent);
    expect(sent, findsOneWidget);
    expect(standInIn(tester, sent)?.bytes, pngBytes);
  });

  testWidgets('the menu offers photos and videos, and the camera', (
    tester,
  ) async {
    await openBob(tester);

    await tester.tap(find.byIcon(icons.attach));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Photos and videos'), findsOneWidget);
    expect(find.text('Take a photo or video'), findsOneWidget);
  });

  testWidgets('on iOS the gallery is Photos', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await openBob(tester);

    await tester.tap(find.byIcon(icons.attach));
    await tester.pumpAndSettle();
    final photos = find.text('Photos');
    final gallery = find.text('Gallery');
    debugDefaultTargetPlatformOverride = null;

    expect(photos, findsOneWidget);
    expect(gallery, findsNothing);
  });

  testWidgets('a video shows at once, compressing then uploading in numbers', (
    tester,
  ) async {
    await openBob(tester);
    final compressing = compressor.videoSteps = StreamController<double>();
    final uploading = session.uploadSteps = StreamController<int>();
    picker.next = pickedFile(
      'clip.mov',
      List.filled(100, 1),
      mimeType: 'video/quicktime',
      isVideo: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pump();
    // The preview screen closes.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OutgoingAttachmentView), findsOneWidget);
    expect(find.text('Compressing…'), findsOneWidget);
    expect(find.text('0:10'), findsOneWidget);

    compressing.add(0.42);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('42%'), findsOneWidget);

    // Leaving the chat doesn't stop it.
    await tester.tap(backButton());
    await tester.pumpAndSettle();
    await compressing.close();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Bob'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Uploading…'), findsOneWidget);

    uploading.add(67);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('67%'), findsOneWidget);

    await uploading.close();
    await tester.pumpAndSettle();
    expect(find.byType(VideoBubbleContent), findsOneWidget);
    expect(find.text('Uploading…'), findsNothing);
    expect(session.calls, contains('upload clip.mp4'));
  });

  testWidgets('a video too long to send is refused, naming the longest', (
    tester,
  ) async {
    compressor.info = const VideoInfo(duration: Duration(minutes: 5));
    await openBob(tester);
    picker.next = pickedFile(
      'long.mov',
      List.filled(64 * 1024 * 1024, 0),
      mimeType: 'video/quicktime',
      isVideo: true,
    );
    await chooseFromMenu(tester, 'Gallery');
    await tester.tap(find.byIcon(icons.send));
    await tester.pumpAndSettle();

    expect(
      find.text('The video is too long to send: it can last up to 1:32.'),
      findsOneWidget,
    );
    expect(find.byType(OutgoingAttachmentView), findsNothing);
  });

  testWidgets('a received video shows its poster and length', (tester) async {
    session.histories[bob] = [
      fileMessage(1),
      DataMessage(
        topic: bob,
        seq: 2,
        from: bob,
        time: at(2),
        head: const MessageHead(mime: MessageHead.draftyMime),
        content: DraftyContent(
          Drafty.video(
            DraftyVideo(
              mimeType: 'video/mp4',
              ref: '/v0/file/s/v.mp4',
              width: 640,
              height: 360,
              duration: const Duration(seconds: 75),
              preview: pngBytes,
            ),
          ),
        ),
      ),
    ];
    session.chats
      ..clear()
      ..add(chat(bob, name: 'Bob', lastSeq: 2, read: 2, lastMessageAt: at(2)));
    await openBob(tester);

    expect(find.byType(VideoBubbleContent), findsOneWidget);
    expect(find.text('1:15'), findsOneWidget);
    expect(
      tester.getSize(find.byType(VideoBubbleContent)).aspectRatio,
      closeTo(640 / 360, 0.01),
    );
  });

  testWidgets('a profile photo given by ref shows once downloaded', (
    tester,
  ) async {
    const photoRef = '/v0/file/s/bob.png';
    session.files[photoRef] = pngBytes;
    session.chats
      ..clear()
      ..add(
        Subscription(
          topic: bob,
          lastSeq: 1,
          read: 1,
          lastMessageAt: at(1),
          public: const Profile(
            name: 'Bob',
            photo: ProfilePhoto(type: 'png', ref: photoRef),
          ),
        ),
      );

    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
    );

    expect(session.calls, contains('download $photoRef'));
    final avatar = tester.widget<CircleAvatar>(
      find.descendant(
        of: find.byType(RefPhotoAvatar),
        matching: find.byType(CircleAvatar),
      ),
    );
    expect(avatar.backgroundImage, isNotNull);
  });
}
