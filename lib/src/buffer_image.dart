library buffer_image;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'blend_mode.dart';
import 'private.dart';
import 'repeat_mode.dart';
import 'sample_mode.dart';

/// An image object
class BufferImage {
  static const bytePerPixel = 4;
  Uint8List _buffer;

  int _width;
  int _height;

  /// create BufferImage with specified `with` and `height`
  BufferImage(width, height)
      : _width = width,
        _height = height,
        _buffer = Uint8List(width * height * bytePerPixel);

  BufferImage._(this._buffer, this._width, this._height);

  /// load data from an [Image]
  static Future<BufferImage> fromImage(Image image) async {
    return BufferImage._(
        (await image.toByteData(format: ImageByteFormat.rawRgba))!
            .buffer
            .asUint8List(),
        image.width,
        image.height);
  }

  /// load image from a `file` use system codec([decodeImageFromList])
  static Future<BufferImage?> fromFile(File file) async {
    return fromImage(await decodeImageFromList(file.readAsBytesSync()));
  }

  int get width {
    return _width;
  }

  int get height {
    return _height;
  }

  /// set the [Color] at Offset(`x`, `y`)
  setColor(int x, int y, Color color) {
    _buffer[y * _width * bytePerPixel + x * bytePerPixel] = color.red;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1] = color.green;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2] = color.blue;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3] = color.alpha;
  }

  /// get the [Color] at Offset(`x`, `y`)
  Color getColor(int x, int y) {
    return Color.fromARGB(
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2],
    );
  }

  /// scale by `ratio` width `sample`
  resize(double ratio, [SampleMode sample = SampleMode.nearest]) {
    int newWidth = (_width * ratio).round();
    int newHeight = (_height * ratio).round();
    resizeTo(newWidth, newHeight, sample);
  }

  /// scale to specified size (`newWidth` and `newHeight`) with `sample`
  resizeTo(int newWidth, int newHeight,
      [SampleMode sample = SampleMode.nearest]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);
    double xr = (_width - 1) / 2;
    double yr = (_height - 1) / 2;
    double nxr = (newWidth - 1) / 2;
    double nyr = (newHeight - 1) / 2;
    double xp = xr / nxr;
    double yp = yr / nyr;

    for (int x = 0; x < newWidth; x++) {
      for (int y = 0; y < newHeight; y++) {
        Color newColor = sample.sample(
            Point<double>((x - nxr) * xp + xr, (y - nyr) * yp + yr), this);
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel] =
            newColor.red;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 1] =
            newColor.green;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 2] =
            newColor.blue;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 3] =
            newColor.alpha;
      }
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  /// Rotate image by the specified `radian`,
  /// The blank area is filled with the specified `bgColor`
  /// If `isClip`, hold the old width & height (clip the image data out of canvas)
  /// Else adjust the canvas to fit the rotated image
  /// `isAntialias` not implemented
  rotate(double radian,
      [bool isAntialias = true,
      Color bgColor = const Color.fromARGB(0, 255, 255, 255),
      bool isClip = false]) {
    int newWidth = _width;
    int newHeight = _height;
    if (!isClip) {
      newWidth = (sin(radian) * _width + cos(radian) * _height).ceil();
      newHeight = (cos(radian) * _width + sin(radian) * _height).ceil();
    }
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);
    double xr = (_width - 1) / 2;
    double yr = (_height - 1) / 2;
    double nxr = (newWidth - 1) / 2;
    double nyr = (newHeight - 1) / 2;

    //List<String> logs = [];
    //rotate
    for (int x = 0; x < newWidth; x++) {
      for (int y = 0; y < newHeight; y++) {
        int xPos = xr.round();
        int yPos = yr.round();

        // 非中心点才可以计算
        if (x != nxr || y != nyr) {
          double r = sqrt(pow(x - nxr, 2) + pow(newHeight - y - nyr, 2));

          double curRadian = (pi / 2);
          if (x != nxr) {
            curRadian = atan((newHeight - y - nyr) / (x - nxr));
            if (x < nxr) {
              curRadian += pi;
            }
          } else if (y > nyr) {
            curRadian += pi;
          }
          double newRadian = curRadian - radian;

          xPos = (cos(newRadian) * r + xr).round();
          yPos = (_height - sin(newRadian) * r - yr).round();
        }
        Point<int> orig = Point(xPos, yPos);
        Color newColor = bgColor;
        if (orig.x >= 0 && orig.x < _width && orig.y >= 0 && orig.y < _height) {
          //logs.add("$x, $y => ${orig.x}, ${orig.y}");
          newColor = getColor(orig.x, orig.y);
        }
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel] =
            newColor.red;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 1] =
            newColor.green;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 2] =
            newColor.blue;
        newBuffer[y * newWidth * bytePerPixel + x * bytePerPixel + 3] =
            newColor.alpha;
      }
    }

    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  /// Clip the image to `newWidth` & `newHeight` from Offset(`offsetX`, `offsetY`)
  clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);

    // 实际clip边界
    int clipWidth = min(newWidth, _width - offsetX);
    int clipHeight = min(newHeight, _height - offsetY);

    for (int y = offsetY; y < offsetY + clipHeight; y++) {
      List.copyRange(
        newBuffer,
        (y - offsetY) * newWidth * bytePerPixel,
        _buffer,
        ((y * _width) + offsetX) * bytePerPixel,
        ((y * _width) + offsetX + clipWidth) * bytePerPixel,
      );
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  /// Mask the image with `color` use `mode`(see [BlendMode])
  mask(Color color, [BlendMode mode = BlendMode.color]) {
    BlendModeAction blend = BlendModeAction(mode);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        Color oColor = getColor(x, y);
        setColor(x, y, blend.blend(color, oColor));
      }
    }
  }

  /// Mask the image with another `image` use `mode`(see [BlendMode])
  maskImage(BufferImage image,
      [BlendMode mode = BlendMode.color,
      Point<int>? offset,
      int repeat = RepeatMode.repeatAll]) {
    BlendModeAction blend = BlendModeAction(mode);
    RepeatMode repeatMode = RepeatMode(repeat);
    ImageSize size = ImageSize(image.width, image.height);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        PixelPoint? oPoint = repeatMode.repeat(
            PixelPoint(x + (offset?.x ?? 0), y + (offset?.y ?? 0)), size);
        if (oPoint != null) {
          Color oColor = getColor(x, y);
          setColor(
              x, y, blend.blend(image.getColor(oPoint.x, oPoint.y), oColor));
        }
      }
    }
  }

  /// the color data of this image
  Uint8List get buffer {
    return _buffer;
  }

  /// A copy of this BufferImage
  BufferImage copy() {
    return BufferImage._(Uint8List.fromList(_buffer), _width, _height);
  }
}
