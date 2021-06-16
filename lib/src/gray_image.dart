import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'abstract_image.dart';
import 'blend_mode.dart';
import 'sample_mode.dart';

/// An gray scaled image, each pixel is a gray value in(0~255)
class GrayImage extends AbstractImage {
  Uint8List _buffer;

  int _width;
  int _height;

  GrayImage(width, height)
      : _width = width,
        _height = height,
        _buffer = Uint8List(width * height);

  GrayImage._(this._buffer, this._width, this._height);

  int get width => _width;
  int get height => _height;

  /// get the gray value(0-255) at Point(x, y). [channel] is ignored
  int getChannel(int x, int y, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    return _buffer[y * _width + x];
  }

  /// get the gray value(0-255) at Point(x, y) without exception. [channel] is ignored
  int getChannelSafe(int x, int y, [int? defaultValue, ImageChannel? channel]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return getChannel(x, y, channel);
    } else if (defaultValue == null) {
      if (x < 0) x = 0;
      if (x > width - 1) x = width - 1;
      if (y < 0) y = 0;
      if (y > height - 1) y = height - 1;
      return getChannel(x, y, channel);
    }
    return defaultValue;
  }

  /// set the gray value(0-255) at Point(x, y). [channel] is ignored
  void setChannel(int x, int y, int value, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    _buffer[y * _width + x] = value;
  }

  /// set the gray value(0-255) at Point(x, y) without exception. [channel] is ignored
  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setChannel(x, y, value, channel);
    }
  }

  Color getColor(int x, int y) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    return Color.fromARGB(
      255,
      _buffer[y * _width + x],
      _buffer[y * _width + x],
      _buffer[y * _width + x],
    );
  }

  Color getColorSafe(int x, int y,
      [Color? defaultColor = const Color(0x00ffffff)]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return getColor(x, y);
    } else if (defaultColor == null) {
      if (x < 0) x = 0;
      if (x > width - 1) x = width - 1;
      if (y < 0) y = 0;
      if (y > height - 1) y = height - 1;
      return getColor(x, y);
    }
    return defaultColor;
  }

  /// set [color](will be grayscale) at Point([x], [y])
  void setColor(int x, int y, Color color) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');

    int maxValue = max(color.red, max(color.green, color.blue));
    int minValue = min(color.red, min(color.green, color.blue));
    int avg = (maxValue + minValue) ~/ 2;
    if (color.alpha < 255 && avg < 255) {
      avg = 255 - ((255 - avg) * ((255 - color.alpha) / 255)).round();
    }
    _buffer[y * _width + x] = avg;
  }

  setColorSafe(int x, int y, Color color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setColor(x, y, color);
    }
  }

  resize(double ratio) {
    resizeTo((_width * ratio).round(), (_height * ratio).round());
  }

  resizeTo(int newWidth, int newHeight,
      [SampleMode sample = SampleMode.nearest]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight);
    double xr = (_width - 1) / 2;
    double yr = (_height - 1) / 2;
    double nxr = (newWidth - 1) / 2;
    double nyr = (newHeight - 1) / 2;
    double xp = xr / nxr;
    double yp = yr / nyr;

    for (int x = 0; x < newWidth; x++) {
      for (int y = 0; y < newHeight; y++) {
        int newValue = sample.sampleChannel(
            Point<double>((x - nxr) * xp + xr, (y - nyr) * yp + yr), this);
        newBuffer[y * newWidth + x] = newValue;
      }
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  rotate(double radian,
      {SampleMode sample = SampleMode.bilinear,
      int bgColor = 255,
      bool isClip = false}) {
    int newWidth = _width;
    int newHeight = _height;
    if (!isClip) {
      newWidth =
          (sin(radian).abs() * _width + cos(radian).abs() * _height).ceil();
      newHeight =
          (cos(radian).abs() * _width + sin(radian).abs() * _height).ceil();
    }
    Uint8List newBuffer = Uint8List(newWidth * newHeight);
    double xr = (_width - 1) / 2;
    double yr = (_height - 1) / 2;
    double nxr = (newWidth - 1) / 2;
    double nyr = (newHeight - 1) / 2;

    //rotate
    for (int x = 0; x < newWidth; x++) {
      for (int y = 0; y < newHeight; y++) {
        double xPos = xr;
        double yPos = yr;

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

          xPos = (cos(newRadian) * r + xr);
          yPos = (_height - sin(newRadian) * r - yr);
        }
        Point<double> orig = Point(xPos, yPos);
        int newValue = bgColor;
        if (orig.x > -1 && orig.x < _width && orig.y > -1 && orig.y < _height) {
          newValue = sample.sampleChannel(orig, this, null, bgColor);
        }
        newBuffer[y * newWidth + x] = newValue;
      }
    }

    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight);

    // 实际clip边界
    int clipWidth = min(newWidth, _width - offsetX);
    int clipHeight = min(newHeight, _height - offsetY);

    for (int y = offsetY; y < offsetY + clipHeight; y++) {
      List.copyRange(
        newBuffer,
        (y - offsetY) * newWidth,
        _buffer,
        ((y * _width) + offsetX),
        ((y * _width) + offsetX + clipWidth),
      );
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer;
  }

  drawRect(Rect rect, Color color, [BlendMode mode = BlendMode.srcOver]) {
    BlendModeAction blend = BlendModeAction(mode);
    int maxX = min(_width, rect.right.round());
    int minY = max(0, rect.top.round());
    int maxY = min(_height, rect.bottom.round());
    for (int x = max(0, rect.left.round()); x < maxX; x++) {
      for (int y = minY; y < maxY; y++) {
        Color oColor = getColor(x, y);
        setColor(x, y, blend.blend(color, oColor));
      }
    }
  }

  /// inverse phase
  void inserve() {
    for (int i = 0; i < _buffer.length; i++) {
      _buffer[i] = 255 - _buffer[i];
    }
  }

  /// binaryzation this image
  void binaryzation({int middle = 0x80}) {
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        int cValue = getChannel(x, y);
        if (cValue > middle) {
          setChannel(x, y, 255);
        } else if (cValue < middle) {
          setChannel(x, y, 0);
        }
      }
    }
  }

  /// Remove noise
  ///
  /// where the point is greater or lower 7 ~ 8 points around it,
  /// replace it by the around lower or higher points's avg
  int deNoise({int middle = 0x80, int disparity = 0x20}) {
    int count = 0;
    for (int x = 1; x < _width - 1; x++) {
      for (int y = 1; y < _height - 1; y++) {
        int cValue = getChannel(x, y);

        List<int> roundValues = [
          getChannel(x - 1, y - 1),
          getChannel(x, y - 1),
          getChannel(x + 1, y - 1),
          getChannel(x - 1, y),
          getChannel(x + 1, y),
          getChannel(x - 1, y + 1),
          getChannel(x, y + 1),
          getChannel(x + 1, y + 1),
        ];
        List<int> lowPoints =
            roundValues.where((rValue) => rValue > cValue + disparity).toList();
        List<int> highPoints =
            roundValues.where((rValue) => rValue < cValue - disparity).toList();

        if (lowPoints.length > 6) {
          count++;
          setChannel(
              x,
              y,
              lowPoints.reduce((value, element) => value + element) ~/
                  lowPoints.length);
        } else if (highPoints.length > 6) {
          count++;
          setChannel(
              x,
              y,
              highPoints.reduce((value, element) => value + element) ~/
                  highPoints.length);
        }
      }
    }
    return count;
  }

  /// the gray data, each element is a gray pixel (0-255)
  Uint8List get buffer => _buffer;

  /// copy and return a new GrayImage
  GrayImage copy() {
    return GrayImage._(Uint8List.fromList(_buffer), _width, _height);
  }
}
