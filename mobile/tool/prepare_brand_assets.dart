import 'dart:io';

// Provided transitively by the launcher/splash build tools.
// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as image;

/// Packages the approved icon artwork for native platform splash constraints.
/// It only resizes, applies the same rounded mask as MotorStockMark, and insets.
void main() {
  final artwork = image
      .decodePng(File('assets/motorstock-icon.png').readAsBytesSync())!
      .convert(numChannels: 4);
  final resized = image.copyResize(
    artwork,
    width: 480,
    height: 480,
    interpolation: image.Interpolation.cubic,
  );
  final mark = image.copyCrop(
    resized,
    x: 0,
    y: 0,
    width: 480,
    height: 480,
    radius: 125,
  );
  File('assets/motorstock-splash.png').writeAsBytesSync(image.encodePng(mark));

  // Android 12 clips a 1152px source to a central 768px circle. The complete
  // 480px rounded square fits inside that circle, including its corners.
  final android12 = image.Image(width: 1152, height: 1152, numChannels: 4);
  image.compositeImage(android12, mark, dstX: 336, dstY: 336);
  File('assets/motorstock-splash-android12.png')
      .writeAsBytesSync(image.encodePng(android12));
}
