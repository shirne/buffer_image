import 'dart:math';
import 'dart:typed_data';

import 'package:buffer_image/src/sample_mode.dart';
import 'package:flutter/painting.dart';

class BufferImage {
  static const bytePerPixel = 4;
  Uint8List _buffer;

  int _width;
  int _height;

  BufferImage(width, height)
      : _width = width,
        _height = height,
        _buffer = Uint8List(width * height * bytePerPixel);

  BufferImage._(this._buffer, this._width, this._height);

  int get width {
    return _width;
  }

  int get height {
    return _height;
  }

  setColor(int x, int y, Color color) {
    _buffer[y * _width * bytePerPixel + x * bytePerPixel] = color.red;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1] = color.green;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2] = color.blue;
    _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3] = color.alpha;
  }

  Color getColor(int x, int y) {
    return Color.fromARGB(
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 3],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 1],
      _buffer[y * _width * bytePerPixel + x * bytePerPixel + 2],
    );
  }

  resize(double ratio, [SampleMode sample = SampleMode.nearest]) {
    int newWidth = (_width * ratio).round();
    int newHeight = (_height * ratio).round();
    resizeTo(newWidth, newHeight, sample);
  }

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

  Uint8List get buffer {
    return _buffer;
  }

  BufferImage copy() {
    return BufferImage._(Uint8List.fromList(_buffer), _width, _height);
  }
}
