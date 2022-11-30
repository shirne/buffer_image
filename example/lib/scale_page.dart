import 'dart:ui' as ui;
import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';

class ScalePage extends StatefulWidget {
  const ScalePage({Key? key}) : super(key: key);

  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends State<ScalePage>
    with AutomaticKeepAliveClientMixin {
  late BufferImage bufferImage;

  ui.Image? image;
  ui.Image? scaleImage;
  ui.Image? scale2Image;

  double _scale = 1;
  final SampleMode _mode = SampleMode.bilinear;

  @override
  void initState() {
    super.initState();
    _createImage();
  }

  @override
  bool get wantKeepAlive => true;

  void _createImage() async {
    print('init image');
    if (image != null) return;
    bufferImage = BufferImage(100, 100);
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        bufferImage.drawRect(Rect.fromLTWH(i * 10.0, j * 10.0, 10, 10),
            Colors.primaries[(j * 10 + i) % Colors.primaries.length]);
      }
    }
    image = await bufferImage.getImage();

    _updateScale(1.5);
  }

  _updateScale(v) async {
    _scale = v;
    var buffer1 = bufferImage.copy();
    buffer1.resize(_scale, _mode);
    scaleImage = await buffer1.getImage();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scale Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text('原始图像:'),
            if (image != null)
              RawImage(
                image: image!,
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                const Text('缩放图像'),
                Expanded(
                    child: Slider(
                  onChanged: _updateScale,
                  value: _scale,
                  max: 3,
                  min: 0.5,
                )),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            if (scaleImage != null)
              RawImage(
                image: scaleImage!,
              ),
          ],
        ),
      ),
    );
  }
}
