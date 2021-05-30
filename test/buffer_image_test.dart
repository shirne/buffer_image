import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buffer_image/buffer_image.dart';

void main() {
  testWidgets('test RgbaImage', (WidgetTester tester) async {
    final bufferImage = BufferImage(100, 100);
    for (int i = 0; i < 100; i++) {
      for (int j = 0; j < 100; j++) {
        bufferImage.setColor(
            i, j, Colors.primaries[(i * 100 + j) % Colors.primaries.length]);
      }
    }
    final image = RgbaImage.fromBufferImage(bufferImage);
    await tester.pumpWidget(Image(image: image));
  });

  test('test BufferImage', () {
    final image = BufferImage(100, 100);

    image.setColor(0, 0, Colors.black);
    expect(image.getColor(0, 0), Colors.black);

    image.rotate(Math.pi / 8);
    print("size after rotate: ${image.width} x ${image.height}");

    image.clip(100, 100, 15, 15);

    print("size after clip: ${image.width} x ${image.height}");
  });

  test('core', () {
    double radian;
    radian = Math.atan(double.maxFinite);
    print(radian);
    print(Math.cos(radian));
  });
}
