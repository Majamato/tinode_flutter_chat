import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

void main() {
  const english = TinodeChatStrings();
  const spanish = TinodeChatStrings.es();
  const french = TinodeChatStrings.fr();

  group('forLocale', () {
    for (final (locale, expected, name) in [
      (const Locale('en'), english, 'English'),
      (const Locale('es'), spanish, 'Spanish'),
      (const Locale('es', 'MX'), spanish, 'Spanish'),
      (const Locale('fr'), french, 'French'),
      (const Locale('fr', 'CA'), french, 'French'),
      (const Locale('de'), english, 'English'),
    ]) {
      test('$locale gets the $name texts', () {
        expect(TinodeChatStrings.forLocale(locale), same(expected));
      });
    }
  });

  test('supportedLocales lists the built-in languages', () {
    expect(TinodeChatStrings.supportedLocales.map((l) => l.languageCode), [
      'en',
      'es',
      'fr',
    ]);
  });

  test('a language constructor keeps the texts it is not given', () {
    const custom = TinodeChatStrings.es(chatListTitle: 'Mis chats');

    expect(custom.chatListTitle, 'Mis chats');
    expect(custom.logOut, spanish.logOut);
  });

  group('Spanish', () {
    test('names people', () {
      expect(spanish.typingOne('Ana'), 'Ana está escribiendo…');
      expect(spanish.typingTwo('Ana', 'Luis'), 'Ana y Luis están escribiendo…');
      expect(spanish.removeMemberConfirmTitle('Ana'), '¿Quitar a Ana?');
    });

    test('counts', () {
      expect(spanish.unreadCount(1), '1 sin leer');
      expect(spanish.unreadCount(5), '5 sin leer');
      expect(spanish.typingMany(3), '3 personas están escribiendo…');
    });
  });

  group('French', () {
    test('names people', () {
      expect(french.typingOne('Léa'), 'Léa écrit…');
      expect(french.typingTwo('Léa', 'Hugo'), 'Léa et Hugo écrivent…');
      expect(french.removeMemberConfirmTitle('Léa'), 'Retirer Léa ?');
    });

    test('counts zero and one in the singular', () {
      expect(french.unreadCount(0), '0 non lu');
      expect(french.unreadCount(1), '1 non lu');
      expect(french.unreadCount(2), '2 non lus');
    });
  });

  group('of', () {
    Future<TinodeChatStrings> stringsUnder(
      WidgetTester tester,
      Locale locale,
    ) async {
      late TinodeChatStrings strings;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: TinodeChatStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) {
              strings = TinodeChatStrings.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      return strings;
    }

    testWidgets('outside a TinodeChat follows the app locale', (tester) async {
      expect(await stringsUnder(tester, const Locale('es')), same(spanish));
      expect(await stringsUnder(tester, const Locale('fr')), same(french));
      expect(await stringsUnder(tester, const Locale('en')), same(english));
    });

    testWidgets('an unsupported app locale falls back to English', (
      tester,
    ) async {
      expect(await stringsUnder(tester, const Locale('de')), same(english));
    });
  });
}
