import 'package:buffer_image/src/private.dart';

class RepeatMode {
  static const none = 0;
  static const repeatX = 1;
  static const repeatY = 2;

  static const repeatAll = repeatX | repeatY;

  final int _mode;
  const RepeatMode(this._mode);

  PixelPoint? repeat(PixelPoint point, ImageSize size) {
    int x = point.x;
    int y = point.y;
    if (_mode | repeatX == repeatX) {
      x %= size.width;
    }
    if (_mode | repeatY == repeatY) {
      y %= size.height;
    }

    if (x >= size.width || y >= size.height || x < 0 || y < 0) {
      return null;
    }
    return PixelPoint(x, y);
  }
}
