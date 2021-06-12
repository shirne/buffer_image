import 'dart:math' as Math;

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';

class RotatePage extends StatefulWidget {
  const RotatePage({Key? key}) : super(key: key);

  @override
  State<RotatePage> createState() => _RotatePageState();
}

class _RotatePageState extends State<RotatePage> with AutomaticKeepAliveClientMixin {
  late BufferImage bufferImage;

  RgbaImage? image;
  RgbaImage? rotateImage;

  double _rotate = 0;
  SampleMode _mode = SampleMode.bilinear;

  @override
  void initState() {
    super.initState();
    _createImage();
  }

  void _createImage() {
    print('init image');
    if (image != null) return;
    bufferImage = BufferImage(100, 100);
    for (int i = 0; i < 100; i++) {
      for (int j = 0; j < 100; j++) {
        bufferImage.setColor(
            i,
            j,
            Colors
                .primaries[(j ~/ 10 * 10 + i ~/ 10) % Colors.primaries.length]);
      }
    }
    image = RgbaImage.fromBufferImage(bufferImage, scale: 1);

    _updateRotate(1.5);
  }

  _updateRotate(v) async {
    _rotate = v;
    var buffer = bufferImage.copy();
    buffer.rotate(_rotate, sample: _mode);
    rotateImage = RgbaImage.fromBufferImage(buffer, scale: 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rotate Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20,),
            Text('原始图像:'),
            Image(
              image: image!,
            ),
            SizedBox(height: 20,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20,),
                Text('旋转图像'),
                Expanded(
                    child: Slider(
                  onChanged: _updateRotate,
                  value: _rotate,
                  max: Math.pi * 2,
                  min: 0,
                )),
                SizedBox(width: 20,),
              ],
            ),
            SizedBox(height: 20,),
            Image(
              image: rotateImage!,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
