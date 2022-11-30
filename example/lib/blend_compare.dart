import 'dart:ui' as ui;
import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlendComparePage extends StatefulWidget {
  const BlendComparePage({Key? key}) : super(key: key);

  @override
  State<BlendComparePage> createState() => _BlendComparePageState();
}

class _BlendComparePageState extends State<BlendComparePage> {
  ui.Image? srcImage;
  ui.Image? dstImage;
  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    final srcBytes = await rootBundle.load('assets/src.png');
    srcImage = await decodeImageFromList(srcBytes.buffer.asUint8List());

    final dstBytes = await rootBundle.load('assets/dst.png');
    dstImage = await decodeImageFromList(dstBytes.buffer.asUint8List());
    setState(() {});
  }

  Future<ui.Image> createImage(
      ui.Image srcImage, ui.Image dstImage, BlendMode blendMode) async {
    final img = await BufferImage.fromImage(dstImage);
    img.drawImage(
        await BufferImage.fromImage(srcImage), Offset.zero, blendMode);
    return img.getImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare with Flutter blendMode'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (srcImage != null && dstImage != null)
              for (final blend in BlendMode.values) ...[
                Center(child: Text(blend.name)),
                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: FittedBox(
                          child: CustomPaint(
                            size: const Size(400, 400),
                            painter: ImagePainter(srcImage!, dstImage!, blend),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<ui.Image>(
                        future: createImage(srcImage!, dstImage!, blend),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return RawImage(
                            image: snapshot.data,
                            fit: BoxFit.fill,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ]
            else
              const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image srcImage;
  final ui.Image dstImage;
  final BlendMode blendMode;
  ImagePainter(this.srcImage, this.dstImage, this.blendMode);
  @override
  bool shouldRepaint(ImagePainter oldDelegate) =>
      srcImage != oldDelegate.srcImage || dstImage != oldDelegate.dstImage;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawImage(dstImage, Offset.zero, Paint()..blendMode = BlendMode.src);

    canvas.drawImage(srcImage, Offset.zero, Paint()..blendMode = blendMode);
  }
}
