import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinode_flutter_chat/src/chats/presentation/chat/photo_time_chip.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_neutrals.dart';
import 'package:tinode_flutter_chat/tinode_flutter_chat.dart';

const _white = Color(0xFFFFFFFF);

/// WCAG contrast ratio of [a] against [b].
double _contrast(Color a, Color b) {
  final (light, dark) = a.computeLuminance() > b.computeLuminance()
      ? (a, b)
      : (b, a);
  return (light.computeLuminance() + 0.05) / (dark.computeLuminance() + 0.05);
}

void main() {
  const palette = TinodeChatPalette.neutral;

  group('fromPalette', () {
    test('uses primary and ink in light mode', () {
      final theme = TinodeChatTheme.fromPalette(palette);

      expect(theme.ownBubbleColor, palette.lightBubble);
      expect(theme.actionColor, palette.primary);
      expect(theme.ownAccentColor, palette.primary);
      expect(theme.readReceiptColor, palette.primary);
      expect(theme.unreadBadgeColor, palette.primary);
      expect(theme.linkColor, palette.ink);
      expect(theme.iconColor, ChatNeutrals.light.text);
      expect(theme.iconPassiveColor, ChatNeutrals.light.muted);
      expect(theme.wallpaperColor, palette.lightWallpaper);
    });

    test('swaps in night and onDark in dark mode', () {
      final theme = TinodeChatTheme.fromPalette(
        palette,
        brightness: Brightness.dark,
      );

      expect(theme.ownBubbleColor, palette.night);
      expect(theme.onOwnBubbleColor, _white);
      expect(theme.actionColor, palette.night);
      expect(theme.unreadBadgeColor, palette.night);
      expect(theme.linkColor, palette.onDark);
      expect(theme.iconColor, ChatNeutrals.dark.text);
      expect(theme.iconPassiveColor, ChatNeutrals.dark.muted);
      expect(theme.wallpaperColor, isNot(palette.soft));
    });

    test('read ticks over media stand out on the photo chip, and from the '
        'white of delivered ones', () {
      // The chip over a white photo, its lightest.
      final chip = Color.alphaBlend(PhotoTimeChip.background, _white);
      for (final brightness in Brightness.values) {
        final theme = TinodeChatTheme.fromPalette(
          palette,
          brightness: brightness,
        );

        expect(
          _contrast(theme.mediaReadReceiptColor, chip),
          greaterThanOrEqualTo(3),
        );
        expect(theme.mediaReadReceiptColor, isNot(_white));
      }
    });

    test('keeps the call screens dark in either mode', () {
      for (final brightness in Brightness.values) {
        final theme = TinodeChatTheme.fromPalette(
          palette,
          brightness: brightness,
        );

        expect(theme.callBackgroundColor, palette.deep);
        expect(theme.callBlobColors.first, palette.primary);
        expect(theme.videoPlaceholderColor, palette.scene);
      }
    });
  });

  test('lights the tab bar lens with the brand, or white in the dark', () {
    final light = TinodeChatTheme.fromPalette(palette);
    final dark = TinodeChatTheme.fromPalette(
      palette,
      brightness: Brightness.dark,
    );

    expect(light.tabBarLensColor, palette.primary.withValues(alpha: 0.1));
    expect(dark.tabBarLensColor, const Color(0x24FFFFFF));
    expect(light.pageColor, isNot(light.cardColor));
    expect(dark.pageColor, isNot(dark.cardColor));
  });

  group('own bubble', () {
    test('has dark text on a light tint in light mode', () {
      final theme = TinodeChatTheme.fromPalette(palette);

      expect(
        ThemeData.estimateBrightnessForColor(theme.ownBubbleColor),
        Brightness.light,
      );
      expect(theme.onOwnBubbleColor, isNot(_white));
    });

    test('text passes 4.5:1 on it in either mode', () {
      for (final brightness in Brightness.values) {
        final theme = TinodeChatTheme.fromPalette(
          palette,
          brightness: brightness,
        );

        expect(
          _contrast(theme.onOwnBubbleColor, theme.ownBubbleColor),
          greaterThanOrEqualTo(4.5),
          reason: '$brightness',
        );
      }
    });

    test('it and the bubbles of others stand out from the light '
        'wallpaper, in every palette', () {
      for (final colors in [palette, _plum]) {
        final theme = TinodeChatTheme.fromPalette(colors);

        expect(
          _contrast(theme.ownBubbleColor, theme.wallpaperColor),
          greaterThanOrEqualTo(1.2),
          reason: '${colors.primary} own',
        );
        expect(
          _contrast(theme.peerBubbleColor, theme.wallpaperColor),
          greaterThanOrEqualTo(1.2),
          reason: '${colors.primary} peer',
        );
      }
    });

    test('its time and ticks pass 4.5:1 on it, in every palette', () {
      for (final colors in [palette, _plum]) {
        for (final brightness in Brightness.values) {
          final theme = TinodeChatTheme.fromPalette(
            colors,
            brightness: brightness,
          );
          final meta = Color.alphaBlend(
            theme.ownMetaColor,
            theme.ownBubbleColor,
          );
          expect(
            _contrast(meta, theme.ownBubbleColor),
            greaterThanOrEqualTo(4.5),
            reason: '${colors.primary} $brightness',
          );
        }
      }
    });

    test("matches the design's light chat: a greyish lavender wallpaper, "
        'white bubbles from others and a muted tint for the own', () {
      final theme = TinodeChatTheme.fromPalette(_plum);

      expect(theme.wallpaperColor, _near(const Color(0xFFE7E3EA)));
      expect(theme.ownBubbleColor, _near(const Color(0xFFD4C3E1)));
      expect(theme.peerBubbleColor, const Color(0xFFFFFFFF));
    });

    test('takes the palette bubble, with white text on a dark one', () {
      const custom = TinodeChatPalette(
        primary: Color(0xFF34507A),
        night: Color(0xFF3F5F8F),
        bright: Color(0xFF6B8CC4),
        accent: Color(0xFFF2A541),
        soft: Color(0xFFE8EDF5),
        ink: Color(0xFF23385A),
        onDark: Color(0xFF9DB8E8),
        deep: Color(0xFF0B1424),
        scene: Color(0xFF172236),
        bubble: Color(0xFF1B5E20),
      );
      final theme = TinodeChatTheme.fromPalette(custom);

      expect(theme.ownBubbleColor, custom.bubble);
      expect(theme.onOwnBubbleColor, _white);
      expect(theme.ownAccentColor, _white);
      expect(
        _contrast(theme.onOwnBubbleColor, theme.ownBubbleColor),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  test('white text passes 4.5:1 on the neutral primary and night', () {
    expect(_contrast(_white, palette.primary), greaterThanOrEqualTo(4.5));
    expect(_contrast(_white, palette.night), greaterThanOrEqualTo(4.5));
  });

  test('copyWith with nothing keeps every value', () {
    final theme = TinodeChatTheme.fromPalette(palette);
    final copy = theme.copyWith();

    for (final (name, read) in _fields) {
      expect(read(copy), read(theme), reason: name);
    }
  });

  test('lerp reaches each end', () {
    final light = TinodeChatTheme.fromPalette(palette);
    final fallback = TinodeChatTheme.fallback(ThemeData());

    for (final (name, read) in _fields) {
      expect(read(light.lerp(fallback, 0)), read(light), reason: name);
      expect(read(light.lerp(fallback, 1)), read(fallback), reason: name);
    }
  });

  group('materialTheme', () {
    test('carries the matching chat theme', () {
      final theme = TinodeChatTheme.materialTheme(brightness: Brightness.dark);

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, palette.night);
      expect(theme.extension<TinodeChatTheme>()?.ownBubbleColor, palette.night);
    });

    test('keeps the brand primary while own bubbles are light', () {
      final theme = TinodeChatTheme.materialTheme();

      expect(theme.colorScheme.primary, palette.primary);
      expect(theme.colorScheme.onPrimary, _white);
      expect(
        theme.extension<TinodeChatTheme>()?.ownBubbleColor,
        palette.lightBubble,
      );
    });

    test('keeps the status bar icons readable', () {
      final light = TinodeChatTheme.materialTheme();
      final dark = TinodeChatTheme.materialTheme(brightness: Brightness.dark);

      expect(
        light.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(
        dark.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
        Brightness.light,
      );
    });

    test('sets the fonts', () {
      final theme = TinodeChatTheme.materialTheme(
        fontFamily: 'Body',
        displayFontFamily: 'Display',
      );

      expect(theme.textTheme.bodyLarge?.fontFamily, 'Body');
      expect(theme.textTheme.displayLarge?.fontFamily, 'Display');
    });
  });
}

/// Every value of a theme, by name, so a new field that copyWith or lerp
/// forgets shows up here.
final List<(String, Object? Function(TinodeChatTheme))> _fields = [
  ('ownBubbleColor', (t) => t.ownBubbleColor),
  ('onOwnBubbleColor', (t) => t.onOwnBubbleColor),
  ('ownMetaColor', (t) => t.ownMetaColor),
  ('peerBubbleColor', (t) => t.peerBubbleColor),
  ('onPeerBubbleColor', (t) => t.onPeerBubbleColor),
  ('peerMetaColor', (t) => t.peerMetaColor),
  ('ownAccentColor', (t) => t.ownAccentColor),
  ('actionColor', (t) => t.actionColor),
  ('onActionColor', (t) => t.onActionColor),
  ('bubbleRadius', (t) => t.bubbleRadius),
  ('bubbleTail', (t) => t.bubbleTail),
  ('photoRadius', (t) => t.photoRadius),
  ('sameRunGap', (t) => t.sameRunGap),
  ('newRunGap', (t) => t.newRunGap),
  ('wallpaperColor', (t) => t.wallpaperColor),
  ('dateChipColor', (t) => t.dateChipColor),
  ('glassColor', (t) => t.glassColor),
  ('glassEdgeColor', (t) => t.glassEdgeColor),
  ('linkColor', (t) => t.linkColor),
  ('iconColor', (t) => t.iconColor),
  ('iconPassiveColor', (t) => t.iconPassiveColor),
  ('unreadBadgeColor', (t) => t.unreadBadgeColor),
  ('onUnreadBadgeColor', (t) => t.onUnreadBadgeColor),
  ('mutedBadgeColor', (t) => t.mutedBadgeColor),
  ('onlineColor', (t) => t.onlineColor),
  ('missedCallColor', (t) => t.missedCallColor),
  ('readReceiptColor', (t) => t.readReceiptColor),
  ('mediaReadReceiptColor', (t) => t.mediaReadReceiptColor),
  ('waveOffColor', (t) => t.waveOffColor),
  ('senderNameColors', (t) => t.senderNameColors),
  ('revealedMessageColor', (t) => t.revealedMessageColor),
  ('callBackgroundColor', (t) => t.callBackgroundColor),
  ('onCallColor', (t) => t.onCallColor),
  ('callBlobColors', (t) => t.callBlobColors),
  ('videoPlaceholderColor', (t) => t.videoPlaceholderColor),
  ('videoBlobColors', (t) => t.videoBlobColors),
  ('callScrimColor', (t) => t.callScrimColor),
  ('callShadeColor', (t) => t.callShadeColor),
  ('callControlColor', (t) => t.callControlColor),
  ('callControlActiveColor', (t) => t.callControlActiveColor),
  ('onCallControlActiveColor', (t) => t.onCallControlActiveColor),
  ('callOutlineColor', (t) => t.callOutlineColor),
  ('callPillColor', (t) => t.callPillColor),
  ('callPillEdgeColor', (t) => t.callPillEdgeColor),
  ('acceptCallColor', (t) => t.acceptCallColor),
  ('pageColor', (t) => t.pageColor),
  ('cardColor', (t) => t.cardColor),
  ('tabBarLensColor', (t) => t.tabBarLensColor),
  ('composerRadius', (t) => t.composerRadius),
  ('fieldRadius', (t) => t.fieldRadius),
  ('buttonRadius', (t) => t.buttonRadius),
  ('sheetRadius', (t) => t.sheetRadius),
  ('cardRadius', (t) => t.cardRadius),
  ('springCurve', (t) => t.springCurve),
  ('springDuration', (t) => t.springDuration),
  ('fadeDuration', (t) => t.fadeDuration),
];

/// The example app's purple palette, which the design was drawn in.
const _plum = TinodeChatPalette(
  primary: Color(0xFF5B1A8C),
  night: Color(0xFF6E29A8),
  bright: Color(0xFF8A3FD1),
  accent: Color(0xFFFF9A3D),
  soft: Color(0xFFF1E5FA),
  ink: Color(0xFF42106A),
  onDark: Color(0xFFC08BFF),
  deep: Color(0xFF1A0730),
  scene: Color(0xFF28133D),
);

/// Matches a color within one step per channel of [expected].
Matcher _near(Color expected) => predicate<Color>(
  (c) => [
    (c.r - expected.r).abs(),
    (c.g - expected.g).abs(),
    (c.b - expected.b).abs(),
  ].every((d) => d * 255 <= 1),
  'within one step of $expected',
);
