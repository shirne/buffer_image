import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';

class MorePage extends StatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage>
    with AutomaticKeepAliveClientMixin {
  late BufferImage bufferImage;

  RgbaImage? image;

  @override
  void initState() {
    super.initState();
    _createImage();
  }

  @override
  bool get wantKeepAlive => true;

  void _createImage() {
    print('init image');
    bufferImage = BufferImage(200, 200);
    for (int i = 0; i < 200; i++) {
      for (int j = 0; j < 200; j++) {
        bufferImage.setColor(
            i,
            j,
            Colors
                .primaries[(j ~/ 10 * 10 + i ~/ 10) % Colors.primaries.length]);
      }
    }
    image = RgbaImage.fromBufferImage(bufferImage, scale: 1);
  }

  drawPath(Path path, Color color) async {
    await bufferImage.drawPath(path, color);
    image = RgbaImage.fromBufferImage(bufferImage, scale: 1);
    setState(() {});
  }

  clipPath(Path path) async {
    await bufferImage.clipPath(path);
    image = RgbaImage.fromBufferImage(bufferImage, scale: 1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rotate Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Container(
              height: 220,
              width: 220,
              color: Color.fromARGB(255, 100, 100, 100),
              child: Center(
                child: Image(
                  image: image!,
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 360,
              child: Wrap(
                direction: Axis.horizontal,
                runSpacing: 10,
                spacing: 10,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        drawPath(
                            Path()
                              ..addRRect(RRect.fromLTRBR(
                                  10, 10, 60, 60, Radius.circular(20))),
                            Colors.green);
                      },
                      child: Text('RRect')),
                  ElevatedButton(
                      onPressed: () {
                        drawPath(
                            Path()
                              ..moveTo(30, 40)
                              ..lineTo(50, 40)
                              ..lineTo(55, 10) // top
                              ..lineTo(60, 40)
                              ..lineTo(90, 40) // right
                              ..lineTo(60, 50)
                              ..lineTo(65, 75) // br
                              ..lineTo(55, 50)
                              ..lineTo(45, 75) // bl
                              ..lineTo(50, 50)
                              ..close(),
                            Colors.red);
                      },
                      child: Text('Star')),
                  ElevatedButton(
                      onPressed: () {
                        drawPath(
                            Path()
                              ..addRRect(RRect.fromLTRBR(
                                  110, 110, 170, 170, Radius.circular(50))),
                            Colors.orange);
                      },
                      child: Text('Circle')),
                  ElevatedButton(
                      onPressed: () {
                        drawPath(
                            Path()..addRect(Rect.fromLTWH(10, 110, 60, 60)),
                            Colors.orange);
                      },
                      child: Text('Rect')),
                  ElevatedButton(
                      onPressed: () {
                        _createImage();
                        setState(() {});
                      },
                      child: Text('Reset')),
                  ElevatedButton(
                    onPressed: () {
                      clipPath(Path()
                        ..moveTo(0, 10)
                        ..lineTo(50, 0)
                        ..lineTo(180, 0)
                        ..lineTo(200, 190)
                        ..lineTo(100, 200)
                        ..lineTo(0, 190)
                        ..close());
                    },
                    child: Text('Clip'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      clipPath(Path()
                        ..moveTo(0, 10)
                        ..lineTo(50, 0)
                        ..lineTo(160, 0)
                        ..lineTo(100, 160)
                        ..close());
                    },
                    child: Text('Clip2'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
