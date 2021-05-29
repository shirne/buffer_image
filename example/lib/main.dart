import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RgbaImage? image;
  RgbaImage? scale1Image;
  RgbaImage? scale2Image;

  @override
  void initState() {
    super.initState();
    _createImage();
  }

  void _createImage() {
    print('init image');
    if (image != null) return;
    BufferImage bufferImage = BufferImage(100, 100);
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

    var buffer1 = bufferImage.copy();
    buffer1.resize(2, SampleMode.bilinear);
    scale1Image = RgbaImage.fromBufferImage(buffer1, scale: 1);

    var buffer2 = bufferImage.copy();
    buffer2.resize(2);
    scale2Image = RgbaImage.fromBufferImage(buffer2, scale: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Image(
              image: image!,
            ),
            Image(
              image: scale1Image!,
            ),
            Image(
              image: scale2Image!,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
