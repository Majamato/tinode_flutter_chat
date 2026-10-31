import 'package:tinode_flutter_chat/src/shared/domain/value_object.dart';

/// Light, dark, or as the device is.
enum AppearanceMode { light, dark, system }

/// The look the user picked on this device, as saved: a palette by its ID
/// (none for the host's default) and the [AppearanceMode].
final class StoredAppearance with ValueObject {
  const StoredAppearance({this.paletteId, this.mode = AppearanceMode.system});

  /// Reads what [toJson] wrote; anything unknown keeps its default.
  factory StoredAppearance.fromJson(Map<String, Object?> json) =>
      StoredAppearance(
        paletteId: switch (json['palette']) {
          final String id => id,
          _ => null,
        },
        mode:
            AppearanceMode.values.asNameMap()[json['mode']] ??
            AppearanceMode.system,
      );

  final String? paletteId;
  final AppearanceMode mode;

  Map<String, Object?> toJson() => {
    if (paletteId != null) 'palette': paletteId,
    'mode': mode.name,
  };

  @override
  List<Object?> get props => [paletteId, mode];
}
