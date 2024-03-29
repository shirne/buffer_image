import 'dart:ui';

/// abstract image
abstract class AbstractImage {
  int get bytePerPixel;
  int get width;
  int get height;
  Color getColor(int x, int y);
  Color getColorSafe(
    int x,
    int y, [
    Color? defaultColor = const Color(0x00ffffff),
  ]);

  int getOffset(int x, int y) {
    return y * width * bytePerPixel + x * bytePerPixel;
  }

  void setColor(int x, int y, Color color);
  void setColorSafe(int x, int y, Color color);

  int getChannel(int x, int y, [ImageChannel? channel]);
  int getChannelSafe(int x, int y, [int? defaultValue, ImageChannel? channel]);
  void setChannel(int x, int y, int value, [ImageChannel? channel]);
  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]);

  List<int> get pixels {
    List<int> _pixels = List.filled(width * height, 0);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        _pixels[y * width + x] = getColor(x, y).value;
      }
    }
    return _pixels;
  }

  /// use for zoom out an image
  void scaleDown(double scale);

  void resize(double ratio);

  void resizeTo(int newWidth, int newHeight);

  void rotate(double radian);

  void clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]);

  void drawRect(Rect rect, Color color);

  void inverse();

  AbstractImage copy();
}

enum ImageChannel { red, green, blue, alpha }
