import 'dart:math' as Math;

import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';

class ScalePage extends StatefulWidget {
  const ScalePage({Key? key}) : super(key: key);

  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends State<ScalePage> with AutomaticKeepAliveClientMixin {

  late BufferImage bufferImage;

  RgbaImage? image;
  RgbaImage? scaleImage;
  RgbaImage? scale2Image;

  double _scale = 1;
  SampleMode _mode = SampleMode.bilinear;

  @override
  void initState() {
    super.initState();
    _createImage();
  }

  @override
  bool get wantKeepAlive => true;

  void _createImage() {
    print('init image');
    if (image != null) return;
    bufferImage = BufferImage(100, 100);
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        bufferImage.drawRect(
            Rect.fromLTWH(i*10.0, j*10.0, 10, 10),
            Colors
                .primaries[(j * 10 + i) % Colors.primaries.length]);
      }
    }
    image = RgbaImage.fromBufferImage(bufferImage, scale: 1);

    _updateScale(1.5);
  }

  _updateScale(v) async{
    _scale = v;
    var buffer1 = bufferImage.copy();
    buffer1.resize(_scale, _mode);
    scaleImage = RgbaImage.fromBufferImage(buffer1, scale: 1);
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scale Image'),
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
                Text('缩放图像'),
                Expanded(child: Slider(
                  onChanged: _updateScale,
                  value: _scale,
                  max: 3,
                  min: 0.5,
                )),
                SizedBox(width: 20,),
              ],
            ),
            SizedBox(height: 20,),
            Image(
              image: scaleImage!,
            ),
          ],
        ),
      ),
    );
  }
}