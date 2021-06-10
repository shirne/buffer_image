library sample_mode;

import 'dart:math';

import 'package:flutter/painting.dart';

import 'buffer_image.dart';

/// abstract class of sample mode
abstract class SampleMode {
  static const nearest = const NearestSampleMode();
  static const bilinear = const BilinearSampleMode();
  static const bicubic = const BicubicSampleMode();
  static const lanczos = const LanczosSampleMode();

  final String mode;
  const SampleMode(this.mode);

  Color sample(Point<double> point, BufferImage image, [Color? obColor]);

  Color lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }
}

/// Nearest sample mode
class NearestSampleMode extends SampleMode {
  const NearestSampleMode() : super('nearest');

  /// sample
  @override
  Color sample(Point<double> point, BufferImage image, [Color? obColor]) {
    return image.getColorSafe(point.x.round(), point.y.round(), obColor);
  }
}

/// Bilinear sample mode
class BilinearSampleMode extends SampleMode {
  const BilinearSampleMode() : super('bilinear');

  @override
  Color sample(Point<double> point, BufferImage image, [Color? obColor]) {
    double x = point.x.floorToDouble();
    double y = point.y.floorToDouble();

    if (x == point.x) {
      if (y == point.y) {
        return image.getColorSafe(x.toInt(), y.toInt(), obColor);
      } else {
        return lerpColor(image.getColorSafe(x.toInt(), point.y.floor(), obColor),
            image.getColorSafe(x.toInt(), point.y.ceil(), obColor), point.y - y);
      }
    } else {
      if (y == point.y) {
        return lerpColor(image.getColorSafe(point.x.floor(), y.toInt(), obColor),
            image.getColorSafe(point.x.ceil(), y.toInt(), obColor), point.x - x);
      }
    }

    // tl, tr, br, bl
    List<Color> colors = [
      image.getColorSafe(point.x.floor(), point.y.floor(), obColor),
      image.getColorSafe(point.x.ceil(), point.y.floor(), obColor),
      image.getColorSafe(point.x.ceil(), point.y.ceil(), obColor),
      image.getColorSafe(point.x.floor(), point.y.ceil(), obColor)
    ];
    double tHor = point.x - x, tVer = point.y - y;

    Color newColor = Color.lerp(Color.lerp(colors[0], colors[1], tHor),
        Color.lerp(colors[3], colors[2], tHor), tVer)!;

    return newColor;
  }
}

/// Bicubic sample mode @Unimplemented
class BicubicSampleMode extends SampleMode {
  const BicubicSampleMode() : super('bicubic');

  @override
  Color sample(Point<double> point, BufferImage image, [Color? obColor]) {
    // TODO: implement sample
    throw UnimplementedError();
  }
}

/// Lanczos sample mode@Unimplemented
class LanczosSampleMode extends SampleMode {
  const LanczosSampleMode() : super('lanczos');

  @override
  Color sample(Point<double> point, BufferImage image, [Color? obColor]) {
    // TODO: implement sample
    throw UnimplementedError();
  }
}
