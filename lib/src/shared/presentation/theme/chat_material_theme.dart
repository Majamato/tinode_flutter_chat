import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_neutrals.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/chat_overlay_style.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_palette.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_theme.dart';

/// The app theme behind `TinodeChatTheme.materialTheme`.
ThemeData chatMaterialTheme({
  required TinodeChatPalette palette,
  required Brightness brightness,
  String? fontFamily,
  String? displayFontFamily,
}) {
  final dark = brightness == Brightness.dark;
  final neutrals = ChatNeutrals.of(brightness);
  final chat = TinodeChatTheme.fromPalette(palette, brightness: brightness);
  final primary = chat.actionColor;
  final colors =
      ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
        primary: primary,
        onPrimary: chat.onActionColor,
        primaryContainer: dark ? palette.night : palette.soft,
        onPrimaryContainer: dark ? chat.onActionColor : palette.ink,
        secondaryContainer: dark ? neutrals.surface : palette.soft,
        onSecondaryContainer: dark ? neutrals.text : palette.ink,
        tertiary: palette.accent,
        error: ChatNeutrals.danger,
        surface: neutrals.background,
        onSurface: neutrals.text,
        onSurfaceVariant: neutrals.muted,
        surfaceContainerLowest: neutrals.background,
        surfaceContainerLow: neutrals.card,
        surfaceContainer: neutrals.surface,
        surfaceContainerHigh: neutrals.surface,
        surfaceContainerHighest: neutrals.surface,
        outline: neutrals.muted,
        outlineVariant: neutrals.line,
        surfaceTint: Colors.transparent,
      );
  final base = ThemeData(
    colorScheme: colors,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: neutrals.background,
  );
  final text = _textTheme(base.textTheme, displayFontFamily);
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(chat.fieldRadius),
    borderSide: BorderSide(color: neutrals.line, width: 1.5),
  );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(chat.buttonRadius),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: neutrals.background,
      foregroundColor: neutrals.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: chatOverlayStyle(brightness),
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutrals.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: ChatNeutrals.danger, width: 1.5),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: ChatNeutrals.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 54),
        shape: buttonShape,
        side: BorderSide(color: neutrals.line, width: 1.5),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: chat.linkColor,
        minimumSize: const Size(44, 44),
        textStyle: text.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: chat.onActionColor,
      shape: const CircleBorder(),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: neutrals.background,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: neutrals.line,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(chat.sheetRadius),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: neutrals.surface,
      selectedColor: primary,
      checkmarkColor: chat.onActionColor,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: text.bodyMedium,
      secondaryLabelStyle: text.bodyMedium?.copyWith(color: chat.onActionColor),
    ),
    dividerTheme: DividerThemeData(color: neutrals.line, space: 1),
    extensions: [chat],
  );
}

/// The chat's type scale on Material's text roles: titles 800, names 700,
/// messages 400, everything else 500; display styles in
/// [displayFontFamily].
TextTheme _textTheme(TextTheme base, String? displayFontFamily) {
  TextStyle? display(TextStyle? style) =>
      style?.copyWith(fontFamily: displayFontFamily, fontWeight: _black);
  return base.copyWith(
    displayLarge: display(base.displayLarge),
    displayMedium: display(base.displayMedium),
    displaySmall: display(base.displaySmall),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 32,
      height: 38 / 32,
      fontWeight: _black,
      letterSpacing: -0.64,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 28,
      height: 34 / 28,
      fontWeight: _black,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontSize: 26,
      height: 32 / 26,
      fontWeight: _black,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18,
      height: 24 / 18,
      fontWeight: _black,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 17,
      height: 22 / 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 14,
      height: 19 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodySmall: base.bodySmall?.copyWith(
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelMedium: base.labelMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.78,
    ),
    labelSmall: base.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
  );
}

const FontWeight _black = FontWeight.w800;
