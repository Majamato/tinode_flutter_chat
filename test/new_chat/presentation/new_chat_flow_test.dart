import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_dart_client/tinode_dart_client.dart';
import 'package:tinode_flutter_chat/src/attachments/domain/picked_file.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/chat_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/application/find_controller.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/add_members_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/find_people_screen.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/group_photo_button.dart';
import 'package:tinode_flutter_chat/src/new_chat/presentation/new_group_screen.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

import '../../support/back_button.dart';
import '../../support/fake_attachment_picker.dart';
import '../../support/fake_tinode_session.dart';
import '../../support/fixtures.dart';
import '../../support/pump_tinode_chat.dart';

const strings = TinodeChatStrings();

void main() {
  late FakeTinodeSession session;

  setUp(() {
    session = FakeTinodeSession(
      chats: [chat(carol, name: 'Carol', lastSeq: 1, lastMessageAt: at(1))],
    );
    session.found['bob,basic:bob'] = [
      const FoundTopic(
        topic: bob,
        public: Profile(name: 'Bob'),
      ),
      const FoundTopic(
        topic: friends,
        public: Profile(name: 'Bob fans'),
        memberCount: 4,
      ),
    ];
  });

  Future<void> openSearch(
    WidgetTester tester, {
    FakeAttachmentPicker? picker,
  }) async {
    await pumpTinodeChat(
      tester,
      session,
      credentials: TinodeCredentials.token(session.token),
      attachmentPicker: picker,
    );
    await tester.tap(find.byTooltip(strings.newChat));
    await tester.pumpAndSettle();
    expect(find.byType(FindPeopleScreen), findsOneWidget);
  }

  Future<void> search(WidgetTester tester, Finder field, String text) async {
    await tester.enterText(field, text);
    await tester.pump(findDebounce);
    await tester.pumpAndSettle();
  }

  testWidgets('finds someone and opens the 1:1 chat with them', (tester) async {
    await openSearch(tester);
    expect(find.text(strings.findHint), findsWidgets);

    await search(tester, find.byType(TextField), 'bob');
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Bob fans'), findsOneWidget);
    expect(find.text(strings.groupLabel), findsOneWidget);

    // The server makes the chat when it is first attached.
    session.chats.add(chat(bob, name: 'Bob', lastMessageAt: at(5)));
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(FindPeopleScreen), findsNothing);
    expect(session.calls, contains('attach $bob'));

    // Back goes straight to the chat list, which now has the chat.
    await tester.tap(find.byTooltip('Back to chats'));
    await tester.pumpAndSettle();
    expect(find.text(strings.chatListTitle), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('a search that finds no one says so', (tester) async {
    await openSearch(tester);
    await search(tester, find.byType(TextField), 'nobody');
    expect(find.text(strings.nobodyFound), findsOneWidget);
  });

  testWidgets('offline the search fails and can be retried', (tester) async {
    await openSearch(tester);
    session.failFind = const ConnectionClosedException('gone');
    await search(tester, find.byType(TextField), 'bob');
    expect(find.text(strings.connectionLost), findsOneWidget);

    await tester.tap(find.text(strings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('the search keeps its row for the field: back is the chevron', (
    tester,
  ) async {
    await openSearch(tester);
    expect(backText(), findsNothing);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(FindPeopleScreen), findsNothing);
  });

  Future<void> openAddMembers(
    WidgetTester tester, {
    FakeAttachmentPicker? picker,
  }) async {
    await openSearch(tester, picker: picker);
    await tester.tap(find.text(strings.newGroup));
    await tester.pumpAndSettle();
    expect(find.byType(AddMembersScreen), findsOneWidget);
  }

  Finder pickedMarks() => find.byIcon(const TinodeChatIcons().picked);

  Finder createButton() => find.widgetWithText(TextButton, strings.createGroup);

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, strings.next));
    await tester.pumpAndSettle();
    expect(find.byType(NewGroupScreen), findsOneWidget);
  }

  testWidgets('back from adding members is the chevron', (tester) async {
    await openAddMembers(tester);
    expect(backText(), findsNothing);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(AddMembersScreen), findsNothing);
    expect(find.byType(FindPeopleScreen), findsOneWidget);
  });

  testWidgets('suggests the direct chats and finds others', (tester) async {
    session.chats.add(chat(friends, name: 'Friends', lastMessageAt: at(2)));
    await openAddMembers(tester);
    expect(find.text(strings.suggestedMembers.toUpperCase()), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    // Groups aren't suggested.
    expect(find.text('Friends'), findsNothing);

    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();
    expect(pickedMarks(), findsOneWidget);
    expect(find.text(strings.selectedCount(1)), findsOneWidget);
    // The tile and the picked card.
    expect(find.text('Carol'), findsNWidgets(2));

    await search(tester, find.byType(TextField), 'bob');
    expect(find.text(strings.moreMembers.toUpperCase()), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    // Only people can be members.
    expect(find.text('Bob fans'), findsNothing);
    // Carol doesn't match: only her picked card is left.
    expect(find.text('Carol'), findsOneWidget);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text(strings.selectedCount(2)), findsOneWidget);
  });

  testWidgets('a filter matching nobody says so', (tester) async {
    await openAddMembers(tester);
    await search(tester, find.byType(TextField), 'nobody');
    expect(find.text('Carol'), findsNothing);
    expect(find.text(strings.nobodyFound), findsOneWidget);
  });

  testWidgets('creates a group with a member and opens it', (tester) async {
    await openAddMembers(tester);
    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text(strings.membersCount(1).toUpperCase()), findsOneWidget);

    expect(tester.widget<TextButton>(createButton()).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Hikers');
    await tester.pump();
    expect(tester.widget<TextButton>(createButton()).onPressed, isNotNull);

    await tester.tap(createButton());
    await tester.pumpAndSettle();
    expect(session.calls, containsAllInOrder(['createGroup Hikers']));
    expect(session.addedMembers['grpNew1'], [carol]);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Hikers'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to chats'));
    await tester.pumpAndSettle();
    expect(find.text(strings.chatListTitle), findsOneWidget);
    expect(find.text('Hikers'), findsOneWidget);
  });

  testWidgets('the group name card starts below the bar', (tester) async {
    tester.view.padding = const FakeViewPadding(top: 120);
    addTearDown(tester.view.resetPadding);
    await openAddMembers(tester);
    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();
    await next(tester);

    final screen = find.byType(NewGroupScreen);
    final bar = find.descendant(
      of: screen,
      matching: find.byType(TinodeAppBar),
    );
    final card = find.ancestor(
      of: find.byType(GroupPhotoButton),
      matching: find.byType(DecoratedBox),
    );
    expect(
      tester.getRect(card.first).top,
      greaterThanOrEqualTo(tester.getRect(bar).bottom),
    );
  });

  testWidgets('a member removed when naming the group is unpicked', (
    tester,
  ) async {
    await openAddMembers(tester);
    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();
    await next(tester);

    await tester.tap(find.byTooltip(strings.removePicked('Carol')));
    await tester.pumpAndSettle();
    expect(find.text(strings.membersCount(0).toUpperCase()), findsOneWidget);
    expect(find.text('Carol'), findsNothing);

    await tester.tap(backButton());
    await tester.pumpAndSettle();
    expect(find.byType(AddMembersScreen), findsOneWidget);
    expect(pickedMarks(), findsNothing);
    expect(find.text(strings.selectedCount(1)), findsNothing);
  });

  testWidgets('the group gets the photo picked', (tester) async {
    final picker = FakeAttachmentPicker(hasCamera: false)
      ..next = pickedFile(
        'hills.png',
        pngBytes,
        mimeType: 'image/png',
        isImage: true,
      );
    await openAddMembers(tester, picker: picker);
    await next(tester);

    await tester.tap(find.byTooltip(strings.groupPhoto));
    await tester.pumpAndSettle();
    expect(picker.picks, [AttachmentSource.gallery]);
    expect(find.byType(Image), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hikers');
    await tester.pump();
    await tester.tap(createButton());
    await tester.pumpAndSettle();
    expect(
      session.calls,
      containsAllInOrder(['upload hills.png', 'createGroup Hikers']),
    );
    expect(session.chats.last.public?.photo?.type, 'png');
  });

  testWidgets('a member the server refuses is reported', (tester) async {
    session.refuseMembers.add(carol);
    await openAddMembers(tester);
    await tester.tap(find.text('Carol'));
    await tester.pumpAndSettle();
    await next(tester);
    await tester.enterText(find.byType(TextField), 'Hikers');
    await tester.pump();

    await tester.tap(createButton());
    await tester.pumpAndSettle();
    expect(find.text(strings.membersNotAdded), findsOneWidget);
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('a group the server refuses stays on the screen', (tester) async {
    session.failCreateGroup = const ServerException(403, 'denied');
    await openAddMembers(tester);
    await next(tester);
    await tester.enterText(find.byType(TextField), 'Hikers');
    await tester.pump();

    await tester.tap(createButton());
    await tester.pumpAndSettle();
    expect(find.text(strings.rejected), findsOneWidget);
    expect(find.byType(NewGroupScreen), findsOneWidget);
  });
}
