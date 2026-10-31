import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinode_flutter_chat/src/appearance/data/appearance_storage.dart';
import 'package:tinode_flutter_chat/src/appearance/domain/stored_appearance.dart';
import 'package:tinode_flutter_chat/src/shared/presentation/theme/tinode_chat_palette.dart';

/// A palette the user can pick on the Appearance screen.
@immutable
final class TinodeAppearancePalette {
  /// A palette named [label], saved on the device by [id].
  const TinodeAppearancePalette({
    required this.id,
    required this.label,
    required this.colors,
  });

  /// Saved on the device to remember the choice. Keep it when you rename
  /// [label] or change [colors].
  final String id;

  /// The name under the swatch, e.g. "Berenjena".
  final String label;

  /// The colors the app's theme is built from.
  final TinodeChatPalette colors;
}

/// The palette and the light, dark or system theme the user picked on
/// this device, on the chat's Appearance screen.
///
/// Load it before `runApp`, pass it to `TinodeChat.appearance`, and build
/// your app's themes from it, so the whole app follows the choice:
///
/// ```dart
/// final appearance = await TinodeAppearance.load(palettes: [
///   TinodeAppearancePalette(
///     id: 'neutral',
///     label: 'Slate',
///     colors: TinodeChatPalette.neutral,
///   ),
/// ]);
/// runApp(
///   ListenableBuilder(
///     listenable: appearance,
///     builder: (context, _) => MaterialApp(
///       theme: TinodeChatTheme.materialTheme(
///         palette: appearance.palette.colors,
///       ),
///       darkTheme: TinodeChatTheme.materialTheme(
///         palette: appearance.palette.colors,
///         brightness: Brightness.dark,
///       ),
///       themeMode: appearance.themeMode,
///       home: TinodeChat(config: config, appearance: appearance),
///     ),
///   ),
/// );
/// ```
///
/// The choice is saved in the app's support directory, for every user of
/// the device. It notifies its listeners whenever the choice changes.
final class TinodeAppearance extends ChangeNotifier {
  /// An appearance that saves nothing, starting from [paletteId] (the
  /// first of [palettes] when null or unknown) and [themeMode]: for tests,
  /// and for apps that keep the choice themselves.
  TinodeAppearance.inMemory({
    required List<TinodeAppearancePalette> palettes,
    String? paletteId,
    ThemeMode themeMode = ThemeMode.system,
  }) : this._(palettes, null, paletteId, themeMode);

  TinodeAppearance._(
    List<TinodeAppearancePalette> palettes,
    this._storage,
    String? paletteId,
    this._themeMode,
  ) : assert(palettes.isNotEmpty, 'Give at least one palette'),
      assert(
        palettes.map((palette) => palette.id).toSet().length == palettes.length,
        'Palette IDs must differ',
      ),
      palettes = List.unmodifiable(palettes) {
    _palette = _find(paletteId) ?? this.palettes.first;
  }

  /// The appearance saved on this device, in one of [palettes], whose
  /// first is the default. Call it after
  /// `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<TinodeAppearance> load({
    required List<TinodeAppearancePalette> palettes,
  }) => loadFrom(FileAppearanceStorage(), palettes: palettes);

  /// [load] from [storage].
  @visibleForTesting
  static Future<TinodeAppearance> loadFrom(
    AppearanceStorage storage, {
    required List<TinodeAppearancePalette> palettes,
  }) async {
    final stored = await storage.read();
    return TinodeAppearance._(
      palettes,
      storage,
      stored.paletteId,
      switch (stored.mode) {
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
        AppearanceMode.system => ThemeMode.system,
      },
    );
  }

  final AppearanceStorage? _storage;

  /// The palettes on offer, in order; the first is the default.
  final List<TinodeAppearancePalette> palettes;

  late TinodeAppearancePalette _palette;
  ThemeMode _themeMode;

  /// The palette picked, or the default.
  TinodeAppearancePalette get palette => _palette;

  /// The palette [resetPalette] goes back to: the first of [palettes].
  TinodeAppearancePalette get defaultPalette => palettes.first;

  /// Light, dark, or as the device is.
  ThemeMode get themeMode => _themeMode;

  /// Picks the palette with [id]; an unknown one changes nothing.
  void selectPalette(String id) {
    final picked = _find(id);
    if (picked == null || picked == _palette) {
      return;
    }
    _palette = picked;
    _changed();
  }

  /// Picks light, dark, or as the device is.
  void selectThemeMode(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    _changed();
  }

  /// Goes back to [defaultPalette]; the theme mode stays.
  void resetPalette() => selectPalette(defaultPalette.id);

  TinodeAppearancePalette? _find(String? id) =>
      palettes.where((palette) => palette.id == id).firstOrNull;

  void _changed() {
    notifyListeners();
    final storage = _storage;
    if (storage == null) {
      return;
    }
    unawaited(
      _saved = storage.write(
        StoredAppearance(
          paletteId: _palette.id,
          mode: switch (_themeMode) {
            ThemeMode.light => AppearanceMode.light,
            ThemeMode.dark => AppearanceMode.dark,
            ThemeMode.system => AppearanceMode.system,
          },
        ),
      ),
    );
  }

  /// Completes once the latest choice is saved.
  @visibleForTesting
  Future<void> get saved => _saved;
  Future<void> _saved = Future.value();
}
