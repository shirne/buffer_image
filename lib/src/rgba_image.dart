library buffer_image;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'buffer_image.dart';

/// ImageProvider of BufferImage to display in ImageWidget
class RgbaImage extends ImageProvider<RgbaImage> {
  final Uint8List bytes;
  final int width;
  final int height;
  final double scale;

  /// initial from a `image`
  RgbaImage.fromBufferImage(BufferImage image, {this.scale = 1.0})
      : bytes = image.buffer,
        width = image.width,
        height = image.height;

  /// initial from rgba `bytes` and the specified `width` & `height`
  const RgbaImage(
    this.bytes, {
    required this.width,
    required this.height,
    this.scale = 1.0,
  });

  @override
  ImageStreamCompleter loadBuffer(RgbaImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: 'RgbaImage(${describeIdentity(key.bytes)})',
    );
  }

  Future<ui.Codec> _loadAsync(
    RgbaImage key,
    DecoderBufferCallback decode,
  ) async {
    assert(key == this);

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
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
  int get hashCode => Object.hash(bytes.hashCode, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RgbaImage')}(${describeIdentity(bytes)}, scale: $scale)';
}
