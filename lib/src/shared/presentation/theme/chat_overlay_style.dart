import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The status bar over a screen of [brightness]: clear, with dark icons
/// over light screens and light ones over dark screens. Leaves the
/// navigation bar to the app.
SystemUiOverlayStyle chatOverlayStyle(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    // Android reads the icons' brightness, iOS the bar's.
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
  );
}
