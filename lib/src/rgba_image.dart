import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:buffer_image/src/buffer_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class RgbaImage extends ImageProvider<RgbaImage> {
  final Uint8List bytes;
  final int width;
  final int height;
  final double scale;

  RgbaImage.fromBufferImage(BufferImage image, {this.scale = 1.0})
      : this.bytes = image.buffer,
        this.width = image.width,
        this.height = image.height;

  const RgbaImage(this.bytes,
      {required this.width, required this.height, this.scale = 1.0});

  @override
  ImageStreamCompleter load(RgbaImage key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'RgbaImage(${describeIdentity(key.bytes)})',
    );
  }

  Future<ui.Codec> _loadAsync(RgbaImage key, DecoderCallback decode) async {
    assert(key == this);

    var buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    var descriptor = ui.ImageDescriptor.raw(buffer,
        width: width, height: height, pixelFormat: ui.PixelFormat.rgba8888);
    return await descriptor.instantiateCodec();
  }

  @override
  Future<RgbaImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<RgbaImage>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is RgbaImage && other.bytes == bytes && other.scale == scale;
  }

  @override
  int get hashCode => hashValues(bytes.hashCode, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RgbaImage')}(${describeIdentity(bytes)}, scale: $scale)';
}
