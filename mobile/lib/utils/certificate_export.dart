import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

import '../l10n/l10n_extension.dart';

/// Renders whatever is wrapped in the [RepaintBoundary] at [boundaryKey] to a
/// PNG and saves it to the device's photo gallery, showing a snackbar with
/// the result. Used for the "Download Certificate" action.
Future<void> saveWidgetToGallery({
  required GlobalKey boundaryKey,
  required BuildContext context,
  required String fileName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final tr = context.trRead;
  try {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('Nothing to capture');

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw StateError('Could not encode image');

    final bytes = byteData.buffer.asUint8List();
    await Gal.putImageBytes(bytes, name: fileName);

    messenger.showSnackBar(
      SnackBar(content: Text(tr('certificateSavedToPhotos'))),
    );
  } on GalException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.type.message)));
  } catch (_) {
    messenger.showSnackBar(
      SnackBar(content: Text(tr('couldNotSaveCertificate'))),
    );
  }
}
