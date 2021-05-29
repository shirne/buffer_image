import 'dart:math';

import 'package:buffer_image/src/buffer_image.dart';
import 'package:flutter/painting.dart';

abstract class SampleMode {
  static const nearest = const NearestSampleMode();
  static const bilinear = const BilinearSampleMode();
  static const bicubic = const BicubicSampleMode();

  final String mode;
  const SampleMode(this.mode);

  Color sample(Point<double> point, BufferImage image);

  Color lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }
}

/// 最近邻法
class NearestSampleMode extends SampleMode {
  const NearestSampleMode() : super('nearest');

  @override
  Color sample(Point<double> point, BufferImage image) {
    int x = point.x.round();
    if (x < 0) x = 0;
    if (x >= image.width) x = image.width - 1;
    int y = point.y.round();
    if (y < 0) y = 0;
    if (y >= image.height) y = image.height - 1;
    return image.getColor(x, y);
  }
}

/// 双线性内插法
class BilinearSampleMode extends SampleMode {
  const BilinearSampleMode() : super('bilinear');

  @override
  Color sample(Point<double> point, BufferImage image) {
    double x = point.x.floorToDouble();
    double y = point.y.floorToDouble();

    if (x == point.x) {
      if (y == point.y) {
        return image.getColor(x.toInt(), y.toInt());
      } else {
        return lerpColor(image.getColor(x.toInt(), point.y.floor()),
            image.getColor(x.toInt(), point.y.ceil()), point.y - y);
      }
    } else {
      if (y == point.y) {
        return lerpColor(image.getColor(point.x.floor(), y.toInt()),
            image.getColor(point.x.ceil(), y.toInt()), point.x - x);
      }
    }

    // tl, tr, br, bl
    List<Color> colors = [
      image.getColor(point.x.floor(), point.y.floor()),
      image.getColor(point.x.ceil(), point.y.floor()),
      image.getColor(point.x.ceil(), point.y.ceil()),
      image.getColor(point.x.floor(), point.y.ceil())
    ];
    double tHor = point.x - x, tVer = point.y - y;

    Color newColor = Color.lerp(Color.lerp(colors[0], colors[1], tHor),
        Color.lerp(colors[3], colors[2], tHor), tVer)!;

    return newColor;
  }
}

/// 立方卷积法
class BicubicSampleMode extends SampleMode {
  const BicubicSampleMode() : super('bicubic');

  @override
  Color sample(Point<double> point, BufferImage image) {
    // TODO: implement sample
    throw UnimplementedError();
  }
}

/// Lanczos
class LanczosSampleMode extends SampleMode {
  const LanczosSampleMode() : super('lanczos');

  @override
  Color sample(Point<double> point, BufferImage image) {
    // TODO: implement sample
    throw UnimplementedError();
  }
}
