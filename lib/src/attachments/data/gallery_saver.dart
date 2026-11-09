import 'dart:developer';

import 'package:gal/gal.dart';

/// Saves the photo or video at [path], which the user took with the
/// in-app camera, to the device's photos (Photos on iOS, the gallery on
/// Android), so it outlives the chat. Never throws: a capture that can't be
/// saved still goes to the chat. Tests pass a fake.
typedef GallerySaver =
    Future<void> Function(String path, {required bool isVideo});

/// A [GallerySaver] over `gal`, which asks for access the first time.
Future<void> saveToGallery(String path, {required bool isVideo}) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
      return;
    }
    if (isVideo) {
      await Gal.putVideo(path);
    } else {
      await Gal.putImage(path);
    }
  } on Object catch (e, stackTrace) {
    log(
      'Could not save a capture to the photos',
      name: 'tinode_flutter_chat',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
