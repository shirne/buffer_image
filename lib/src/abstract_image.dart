import 'dart:ui';

abstract class AbstractImage {
  int get width;
  int get height;
  Color getColor(int x, int y);
  Color getColorSafe(int x, int y,
      [Color? defaultColor = const Color(0x00ffffff)]);

  void setColor(int x, int y, Color color);
  void setColorSafe(int x, int y, Color color);

  int getChannel(int x, int y, [ImageChannel? channel]);
  int getChannelSafe(int x, int y, [int? defaultValue, ImageChannel? channel]);
  void setChannel(int x, int y, int value, [ImageChannel? channel]);
  void setChannelSafe(int x, int y, int value, [ImageChannel? channel]);

  resize(double ratio);

  resizeTo(int newWidth, int newHeight);

  rotate(double radian);

  clip(int newWidth, int newHeight, [int offsetX = 0, int offsetY = 0]);

  drawRect(Rect rect, Color color);
}

enum ImageChannel { red, green, blue, alpha }