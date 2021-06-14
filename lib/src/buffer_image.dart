library buffer_image;

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'abstract_image.dart';
import 'gray_image.dart';
import 'blend_mode.dart';
import 'private.dart';
import 'repeat_mode.dart';
import 'sample_mode.dart';

/// An image object, pixel data stored in a [Uint8List]
class BufferImage extends AbstractImage {
  static const bytePerPixel = 4;
  Uint8List _buffer;

  bool _isLock = false;
  int _width;
  int _height;

  /// create BufferImage with specified [with] and [height]
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

  /// load image from a image [fileData] use system codec([decodeImageFromList])
  static Future<BufferImage?> fromFile(Uint8List fileData) async {
    return fromImage(await decodeImageFromList(fileData));
  }

  int get width => _width;

  int get height => _height;

  _lockWrite() {
    assert(!_isLock, 'Can\'t lock image to write!');
    _isLock = true;
  }

  int getChannel(int x, int y, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    assert(channel != null);
    return _buffer[
        y * _width * bytePerPixel + x * bytePerPixel + channel!.index];
  }

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

  void setChannel(int x, int y, int value, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    assert(channel != null);
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + channel!.index] =
        value;
  }

  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setChannel(x, y, value, channel);
    }
  }

  /// set the [Color] at Offset([x], [y])
  setColor(int x, int y, Color color) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    _buffer[y * _width * bytePerPixel + x * bytePerPixel] = color.red;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1] = color.green;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2] = color.blue;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3] = color.alpha;
  }

  /// set [Color] at Offset([x], [y]) without error
  setColorSafe(int x, int y, Color color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setColor(x, y, color);
    }
  }

  /// get the [Color] at Offset([x], [y])
  Color getColor(int x, int y) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    return Color.fromARGB(
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2],
    );
  }

  /// get the [Color] at Offset([x], [y]) with out error
  ///
  /// if out of boundary return [defaultColor]
  /// if defaultColor is `null` return nearest boundary color
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

  /// scale by [ratio] width [sample]
  resize(double ratio, [SampleMode sample = SampleMode.nearest]) {
    int newWidth = (_width * ratio).round();
    int newHeight = (_height * ratio).round();
    resizeTo(newWidth, newHeight, sample);
  }

  /// scale to specified size ([newWidth] and [newHeight]) with [sample]
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
      {bool isAntialias = true,
      SampleMode sample = SampleMode.bilinear,
      Color bgColor = const Color.fromARGB(0, 255, 255, 255),
      bool isClip = false}) {
    int newWidth = _width;
    int newHeight = _height;
    if (!isClip) {
      newWidth =
          (sin(radian).abs() * _width + cos(radian).abs() * _height).ceil();
      newHeight =
          (cos(radian).abs() * _width + sin(radian).abs() * _height).ceil();
    }
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);
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
        Color newColor = bgColor;
        if (orig.x > -1 && orig.x < _width && orig.y > -1 && orig.y < _height) {
          newColor = sample.sample(orig, this, bgColor);
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

  /// Clip this image with [path], use a [Canvas] render
  clipPath(Path path, {bool doAntiAlias = true}) async {
    _lockWrite();
    Rect boundary = path.getBounds();
    PictureRecorder pr = PictureRecorder();
    Canvas canvas = Canvas(pr);
    Image image = await getImage();

    canvas.clipPath(path, doAntiAlias: doAntiAlias);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.save();
    Picture picture = pr.endRecording();
    image = await picture.toImage(min(boundary.width.round(), _width),
        min(boundary.height.round(), _height));
    _buffer = (await image.toByteData(format: ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    _width = image.width;
    _height = image.height;
    _isLock = false;
  }

  /// Mask the image with [color] use [mode](see [BlendMode])
  mask(Color color, [BlendMode mode = BlendMode.color]) {
    BlendModeAction blend = BlendModeAction(mode);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        Color oColor = getColor(x, y);
        setColor(x, y, blend.blend(color, oColor));
      }
    }
  }

  /// Mask the image with another [image] use [mode](see [BlendMode])
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

  /// Draw a [rect] on this image with [color], use the [mode]
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

  /// Draw the [image] on this image at [offset], use the [mode]
  drawImage(BufferImage image, Offset offset,
      [BlendMode mode = BlendMode.srcOver]) {
    BlendModeAction blend = BlendModeAction(mode);
    int minX = max(0, offset.dx.round());
    int maxX = min(_width, (offset.dx + image.width).round());
    int minY = max(0, offset.dy.round());
    int maxY = min(_height, (offset.dy + image.height).round());

    for (int x = minX; x < maxX; x++) {
      for (int y = minY; y < maxY; y++) {
        Color oColor = getColor(x, y);
        setColor(x, y, blend.blend(image.getColor(x - minX, y - minY), oColor));
      }
    }
  }

  /// Draw the [path] on this image, use a [Canvas] render
  drawPath(Path path, Color color,
      {BlendMode mode = BlendMode.srcOver,
      PaintingStyle style = PaintingStyle.fill,
      double strokeWidth = 0}) async {
    _lockWrite();
    Rect boundary = path.getBounds();
    PictureRecorder pr = PictureRecorder();
    Canvas canvas = Canvas(pr);
    Image image = await getImage();
    canvas.drawImage(image, Offset.zero, Paint());

    Paint paint = Paint()
      ..color = color
      ..blendMode = mode
      ..style = style
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, paint);
    canvas.save();
    Picture picture = pr.endRecording();
    image = await picture.toImage(max(boundary.width.round(), _width),
        max(boundary.height.round(), _height));
    _buffer = (await image.toByteData(format: ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    _width = image.width;
    _height = image.height;
    _isLock = false;
  }

  /// Get the [Image] Object from this image
  Future<Image> getImage() async {
    var ib = await ImmutableBuffer.fromUint8List(_buffer);

    ImageDescriptor id = ImageDescriptor.raw(ib,
        width: width, height: height, pixelFormat: PixelFormat.rgba8888);

    Codec cdc = await id.instantiateCodec();

    FrameInfo fi = await cdc.getNextFrame();
    return fi.image;
  }

  /// the color data of this image
  Uint8List get buffer => _buffer;

  GrayImage toGray() {
    GrayImage image = GrayImage(_width, _height);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        image.setColor(x, y, getColor(x, y));
      }
    }
    return image;
  }

  static BufferImage fromGray(GrayImage grayImage) {
    BufferImage image = BufferImage(grayImage.width, grayImage.height);
    for (int x = 0; x < grayImage.width; x++) {
      for (int y = 0; y < grayImage.height; y++) {
        image.setColor(x, y, grayImage.getColor(x, y));
      }
    }
    return image;
  }

  /// A copy of this BufferImage
  BufferImage copy() {
    return BufferImage._(Uint8List.fromList(_buffer), _width, _height);
  }
}
