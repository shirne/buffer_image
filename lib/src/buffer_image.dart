library buffer_image;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' hide TextStyle;
import 'package:flutter/widgets.dart' show IconData;

import 'abstract_image.dart';
import 'gray_image.dart';
import 'blend_mode.dart';
import 'private.dart';
import 'repeat_mode.dart';
import 'sample_mode.dart';

/// An image object, pixel data stored in a [Uint8List]
class BufferImage extends AbstractImage {
  static const _bytePerPixel = 4;
  @override
  int get bytePerPixel => 4;

  ByteData _buffer;

  Completer<bool>? _locker;
  int _width;
  int _height;

  /// create BufferImage with specified [with] and [height]
  BufferImage(width, height)
      : _width = width,
        _height = height,
        _buffer = Uint8List(width * height * _bytePerPixel).buffer.asByteData();

  BufferImage._(this._buffer, this._width, this._height);

  /// load data from an [Image]
  static Future<BufferImage> fromImage(Image image) async {
    return BufferImage._(
      (await image.toByteData(format: ImageByteFormat.rawRgba))!
          .buffer
          .asByteData(),
      image.width,
      image.height,
    );
  }

  /// load image from a image [fileData] use system codec([decodeImageFromList])
  static Future<BufferImage?> fromFile(Uint8List fileData) async {
    return fromImage(await decodeImageFromList(fileData));
  }

  @override
  int get width => _width;

  @override
  int get height => _height;

  Future<void> _lockWrite() async {
    if (_locker != null && !_locker!.isCompleted) {
      await _locker!.future;
    }
    _locker = Completer();
  }

  _unLock([bool success = true]) {
    if (_locker != null && !_locker!.isCompleted) {
      _locker!.complete(success);
    }
  }

  @override
  int getChannel(int x, int y, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    assert(channel != null);
    return _buffer.getUint8(
        y * _width * bytePerPixel + x * bytePerPixel + channel!.index);
  }

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

  @override
  void setChannel(int x, int y, int value, [ImageChannel? channel]) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    assert(channel != null);
    _buffer.setUint8(
      y * _width * bytePerPixel + x * bytePerPixel + channel!.index,
      value,
    );
  }

  @override
  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setChannel(x, y, value, channel);
    }
  }

  /// set the [Color] at Offset([x], [y])
  @override
  void setColor(int x, int y, Color color) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    final offset = getOffset(x, y);
    _buffer.setUint8(offset, color.red);
    _buffer.setUint8(offset + 1, color.green);
    _buffer.setUint8(offset + 2, color.blue);
    _buffer.setUint8(offset + 3, color.alpha);
  }

  /// set [Color] at Offset([x], [y]) without error
  @override
  void setColorSafe(int x, int y, Color color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      setColor(x, y, color);
    }
  }

  /// get the [Color] at Offset([x], [y])
  @override
  Color getColor(int x, int y) {
    assert(x >= 0 && x < width, 'x($x) out of with boundary(0 - $width)');
    assert(y >= 0 && y < height, 'y($y) out of height boundary(0 - $height)');
    final offset = y * _width * bytePerPixel + x * bytePerPixel;
    return Color.fromARGB(
      _buffer.getUint8(offset + 3),
      _buffer.getUint8(offset),
      _buffer.getUint8(offset + 1),
      _buffer.getUint8(offset + 2),
    );
  }

  /// get the [Color] at Offset([x], [y]) with out error
  ///
  /// if out of boundary return [defaultColor]
  /// if defaultColor is `null` return nearest boundary color
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

  /// scale by [ratio] width [sample]
  @override
  void resize(double ratio, [SampleMode sample = SampleMode.nearest]) {
    int newWidth = (_width * ratio).round();
    int newHeight = (_height * ratio).round();
    resizeTo(newWidth, newHeight, sample);
  }

  /// scale to specified size ([newWidth] and [newHeight]) with [sample]
  @override
  void resizeTo(int newWidth, int newHeight,
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
        final offset = y * newWidth * bytePerPixel + x * bytePerPixel;
        Color newColor = sample.sample(
            Point<double>((x - nxr) * xp + xr, (y - nyr) * yp + yr), this);
        newBuffer[offset] = newColor.red;
        newBuffer[offset + 1] = newColor.green;
        newBuffer[offset + 2] = newColor.blue;
        newBuffer[offset + 3] = newColor.alpha;
      }
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  /// zoom out an image.
  /// calc the avg channels of the colors in area as the new color
  @override
  scaleDown(double scale) {
    int newWidth = (width / scale).ceil();
    int newHeight = (height / scale).ceil();
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);
    List<Color?> colors = List.filled(scale.ceil() * scale.ceil(), null);
    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        int count = 0;
        colors.fillRange(0, colors.length, null);
        int startY = (y * scale).round();
        int startX = (x * scale).round();
        int endY = ((y + 1) * scale).ceil();
        int endX = ((x + 1) * scale).ceil();
        //print("$x,$y => ($startX, $startY) ($endX, $endY)");
        for (int sy = startY; sy < endY; sy++) {
          if (sy >= height) break;
          for (int sx = startX; sx < endX; sx++) {
            if (sx >= width) break;
            count++;
            colors[(sy - startY) * (endX - startX) + sx - startX] =
                getColor(sx, sy);
          }
        }
        if (count < 1) break;

        int alpha = 0;
        int red = 0;
        int green = 0;
        int blue = 0;
        for (Color? color in colors) {
          if (color != null) {
            alpha += color.alpha;
            red += color.red;
            green += color.green;
            blue += color.blue;
          }
        }
        final offset = y * newWidth * bytePerPixel + x * bytePerPixel;
        newBuffer[offset] = (red / count).round();
        newBuffer[offset + 1] = (green / count).round();
        newBuffer[offset + 2] = (blue / count).round();
        newBuffer[offset + 3] = (alpha / count).round();
      }
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  /// Rotate image by the specified `radian`,
  /// The blank area is filled with the specified `bgColor`
  /// If `isClip`, hold the old width & height (clip the image data out of canvas)
  /// Else adjust the canvas to fit the rotated image
  /// `isAntialias` not implemented
  @override
  void rotate(double radian,
      {bool isAntialias = true,
      SampleMode sample = SampleMode.bilinear,
      Color bgColor = const Color.fromARGB(0, 255, 255, 255),
      bool isClip = false}) {
    int newWidth = _width;
    int newHeight = _height;
    if (!isClip) {
      newWidth =
          (cos(radian).abs() * _width + sin(radian).abs() * _height).ceil();
      newHeight =
          (sin(radian).abs() * _width + cos(radian).abs() * _height).ceil();
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
        final offset = y * newWidth * bytePerPixel + x * bytePerPixel;
        newBuffer[offset] = newColor.red;
        newBuffer[offset + 1] = newColor.green;
        newBuffer[offset + 2] = newColor.blue;
        newBuffer[offset + 3] = newColor.alpha;
      }
    }

    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  /// Clip the image to `newWidth` & `newHeight` from Offset(`offsetX`, `offsetY`)
  @override
  void clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]) {
    Uint8List newBuffer = Uint8List(newWidth * newHeight * bytePerPixel);

    // 实际clip边界
    int clipWidth = min(newWidth, _width - offsetX);
    int clipHeight = min(newHeight, _height - offsetY);

    for (int y = offsetY; y < offsetY + clipHeight; y++) {
      List.copyRange(
        newBuffer,
        (y - offsetY) * newWidth * bytePerPixel,
        _buffer.buffer.asUint8List(),
        ((y * _width) + offsetX) * bytePerPixel,
        ((y * _width) + offsetX + clipWidth) * bytePerPixel,
      );
    }
    _width = newWidth;
    _height = newHeight;
    _buffer = newBuffer.buffer.asByteData();
  }

  /// Clip this image with [path], use a [Canvas] render
  Future<void> clipPath(Path path, {bool doAntiAlias = true}) async {
    await _lockWrite();
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
        .asByteData();
    _width = image.width;
    _height = image.height;
    _unLock();
  }

  /// Mask the image with [color] use [mode](see [BlendMode])
  void mask(Color color, [BlendMode mode = BlendMode.color]) {
    BlendModeAction blend = BlendModeAction(mode);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        Color oColor = getColor(x, y);
        setColor(x, y, blend.blend(color, oColor));
      }
    }
  }

  /// Mask the image with another [image] use [mode](see [BlendMode])
  void maskImage(BufferImage image,
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

  Future<void> drawIcon(IconData icon, double size, Offset offset, Color color,
      [BlendMode mode = BlendMode.srcOver]) async {
    await _lockWrite();
    PictureRecorder pr = PictureRecorder();
    Canvas canvas = Canvas(pr);
    Image image = await getImage();
    canvas.drawImage(image, Offset.zero, Paint());
    final pb = ParagraphBuilder(ParagraphStyle(
      fontFamily: icon.fontFamily,
      fontSize: size,
    ))
      ..pushStyle(TextStyle(color: color))
      ..addText(String.fromCharCode(icon.codePoint))
      ..pop();
    canvas.drawParagraph(
        pb.build()..layout(ParagraphConstraints(width: size)), offset);
    canvas.save();
    Picture picture = pr.endRecording();
    image = await picture.toImage(_width, _height);
    _buffer = (await image.toByteData(format: ImageByteFormat.rawRgba))!
        .buffer
        .asByteData();
    _width = image.width;
    _height = image.height;
    _unLock();
  }

  Future<void> drawText(String text, TextStyle style, Offset offset,
      [BlendMode mode = BlendMode.srcOver]) async {
    await _lockWrite();
    PictureRecorder pr = PictureRecorder();
    Canvas canvas = Canvas(pr);
    Image image = await getImage();
    canvas.drawImage(image, Offset.zero, Paint());
    final pb = ParagraphBuilder(ParagraphStyle())
      ..pushStyle(style)
      ..addText(text)
      ..pop();
    canvas.drawParagraph(
        pb.build()..layout(ParagraphConstraints(width: width.toDouble())),
        offset);
    canvas.save();
    Picture picture = pr.endRecording();
    image = await picture.toImage(_width, _height);
    _buffer = (await image.toByteData(format: ImageByteFormat.rawRgba))!
        .buffer
        .asByteData();
    _width = image.width;
    _height = image.height;
    _unLock();
  }

  /// Draw a [rect] on this image with [color], use the [mode]
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

  /// Draw the [image] on this image at [offset], use the [mode]
  void drawImage(BufferImage image, Offset offset,
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
  Future<void> drawPath(Path path, Color color,
      {BlendMode mode = BlendMode.srcOver,
      PaintingStyle style = PaintingStyle.fill,
      double strokeWidth = 0}) async {
    await _lockWrite();
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
        .asByteData();
    _width = image.width;
    _height = image.height;
    _unLock();
  }

  /// inverse phase
  @override
  void inverse() {
    for (int i = 0; i < _buffer.lengthInBytes; i++) {
      if (i % bytePerPixel != 3) {
        _buffer.setUint8(i, 255 - _buffer.getUint8(i));
      }
    }
  }

  /// Get the [Image] Object from this image
  Future<Image> getImage() async {
    var ib = await ImmutableBuffer.fromUint8List(_buffer.buffer.asUint8List());

    ImageDescriptor id = ImageDescriptor.raw(ib,
        width: width, height: height, pixelFormat: PixelFormat.rgba8888);

    Codec cdc = await id.instantiateCodec();

    FrameInfo fi = await cdc.getNextFrame();
    return fi.image;
  }

  /// the color data of this image
  Uint8List get buffer => _buffer.buffer.asUint8List();

  GrayImage toGray([GrayScale? grayScale]) {
    GrayImage image = GrayImage(_width, _height);
    for (int x = 0; x < _width; x++) {
      for (int y = 0; y < _height; y++) {
        image.setColor(x, y, getColor(x, y), grayScale);
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
  @override
  BufferImage copy() {
    return BufferImage._(
      Uint8List.fromList(_buffer.buffer.asUint8List()).buffer.asByteData(),
      _width,
      _height,
    );
  }
}
