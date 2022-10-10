import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'abstract_image.dart';
import 'blend_mode.dart';
import 'sample_mode.dart';

typedef GrayScale = int Function(int, int, int);

int gsAvgChannel(int r, int g, int b) => (r + g + b) ~/ 3;

int gsPsychologic(int r, int g, int b) =>
    (r * 0.299 + g * 0.587 + b * 0.114).round();

int gsDesathm(int r, int g, int b) =>
    (max(r, max(g, b)) + min(r, min(g, b))) ~/ 2;

int gsLighter(int r, int g, int b) => max(r, max(g, b));
int gsDarker(int r, int g, int b) => min(r, min(g, b));

int gsRedChannel(int r, int g, int b) => r;
int gsGreenChannel(int r, int g, int b) => g;
int gsBlurChannel(int r, int g, int b) => b;

/// An gray scaled image, each byte is a gray value in(0~255)
class GrayImage extends AbstractImage {
  @override
  int get bytePerPixel => 1;

  ByteData _buffer;

  int _width;
  int _height;

  GrayImage(width, height)
      : _width = width,
        _height = height,
        _buffer = Uint8List(width * height).buffer.asByteData();

  GrayImage._(this._buffer, this._width, this._height);

  GrayImage.raw(Uint8List data, {required int width, required int height})
      : this._(data.buffer.asByteData(), width, height);

  @override
  int get width => _width;
  @override
  int get height => _height;

  /// get the gray value(0-255) at Point(x, y). [channel] is ignored
  @override
  int getChannel(int x, int y, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    return _buffer.getUint8(y * _width + x);
  }

  /// get the gray value(0-255) at Point(x, y) without exception. [channel] is ignored
  @override
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
  @override
  void setChannel(int x, int y, int value, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    _buffer.setUint8(y * _width + x, value);
  }

  /// set the gray value(0-255) at Point(x, y) without exception. [channel] is ignored
  @override
  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setChannel(x, y, value, channel);
    }
  }

  @override
  Color getColor(int x, int y) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    final channel = _buffer.getUint8(y * _width + x);
    return Color.fromARGB(
      255,
      channel,
      channel,
      channel,
    );
  }

  @override
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
  @override
  void setColor(int x, int y, Color color, [GrayScale? grayScale]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');

    int gray = (grayScale ?? gsPsychologic).call(
      color.red,
      color.green,
      color.blue,
    );
    if (color.alpha < 255 && gray < 255) {
      gray = 255 - ((255 - gray) * ((255 - color.alpha) / 255)).round();
    }
    _buffer.setUint8(y * _width + x, gray);
  }

  @override
  void setColorSafe(int x, int y, Color color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setColor(x, y, color);
    }
  }

  @override
  void resize(double ratio) {
    resizeTo((_width * ratio).round(), (_height * ratio).round());
  }

  @override
  void resizeTo(
    int newWidth,
    int newHeight, [
    SampleMode sample = SampleMode.nearest,
  ]) {
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
    _buffer = newBuffer.buffer.asByteData();
  }

  @override
  void scaleDown(double scale) {
    int newWidth = (width / scale).ceil();
    int newHeight = (height / scale).ceil();
    int scaleCeil = scale.ceil();
    Uint8List newBuffer = Uint8List(newWidth * newHeight);
    List<int?> colors = List.filled(scaleCeil * scaleCeil, null);
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        int count = 0;
        colors.fillRange(0, colors.length, null);
        int startY = (y * scale).round();
        int startX = (x * scale).round();
        int endY = startY + scaleCeil;
        int endX = startX + scaleCeil;
        for (int sy = startY; sy < endY; sy++) {
          if (sy >= height) break;
          for (int sx = startX; sx < endX; sx++) {
            if (sx >= width) break;
            count++;
            colors[(sy - startY) * scaleCeil + sx - startX] =
                getChannel(sx, sy);
          }
        }
        if (count < 1) break;

        int newColor = 0;
        for (int? color in colors) {
          if (color != null) {
            newColor += color;
          }
        }
        newBuffer[y * newWidth + x] = (newColor / count).round();
      }
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  @override
  void rotate(double radian,
      {SampleMode sample = SampleMode.bilinear,
      int bgColor = 255,
      bool isClip = false}) {
    int newWidth = _width;
    int newHeight = _height;
    if (!isClip) {
      newWidth =
          (cos(radian).abs() * _width + sin(radian).abs() * _height).ceil();
      newHeight =
          (sin(radian).abs() * _width + cos(radian).abs() * _height).ceil();
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
    _buffer = newBuffer.buffer.asByteData();
  }

  @override
  void clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight);

    // 实际clip边界
    int clipWidth = min(newWidth, _width - offsetX);
    int clipHeight = min(newHeight, _height - offsetY);

    for (int y = offsetY; y < offsetY + clipHeight; y++) {
      List.copyRange(
        newBuffer,
        (y - offsetY) * newWidth,
        _buffer.buffer.asUint8List(),
        ((y * _width) + offsetX),
        ((y * _width) + offsetX + clipWidth),
      );
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  @override
  void drawRect(Rect rect, Color color, [BlendMode mode = BlendMode.srcOver]) {
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
  @override
  void inverse() {
    for (int i = 0; i < _buffer.lengthInBytes; i++) {
      _buffer.setUint8(i, 255 - _buffer.getUint8(i));
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

  /// Get the [Image] Object from this image
  Future<Image> getImage() async {
    final length = buffer.length;
    final origData = Uint8List(length * 4);
    for (int i = 0; i < length; i++) {
      origData[i * 4] = buffer[i];
      origData[i * 4 + 1] = buffer[i];
      origData[i * 4 + 2] = buffer[i];
      origData[i * 4 + 3] = 0xff;
    }
    var ib = await ImmutableBuffer.fromUint8List(origData);

    ImageDescriptor id = ImageDescriptor.raw(ib,
        width: width, height: height, pixelFormat: PixelFormat.rgba8888);

    Codec cdc = await id.instantiateCodec();

    FrameInfo fi = await cdc.getNextFrame();
    return fi.image;
  }

  /// the gray data, each element is a gray pixel (0-255)
  Uint8List get buffer => _buffer.buffer.asUint8List();

  /// copy and return a new GrayImage
  @override
  GrayImage copy() {
    return GrayImage._(
      Uint8List.fromList(_buffer.buffer.asUint8List()).buffer.asByteData(),
      _width,
      _height,
    );
  }
}
