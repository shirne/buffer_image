import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class BlendPage extends StatefulWidget {
  const BlendPage({Key? key}) : super(key: key);
  @override
  State<BlendPage> createState() => _BlendPageState();
}

class _BlendPageState extends State<BlendPage>
    with AutomaticKeepAliveClientMixin {
  late BufferImage bufferImage;

  RgbaImage? image;
  RgbaImage? rotateImage;

  Color _currentColor = Colors.green;
  BlendMode _mode = BlendMode.color;

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

    _updateBlend();
  }

  _updateBlend() async {
    var buffer = bufferImage.copy();
    buffer.mask(_currentColor, _mode);
    rotateImage = RgbaImage.fromBufferImage(buffer, scale: 1);
    setState(() {});
  }

  _pickerColor() {
    Color pickerColor = _currentColor;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: pickerColor,
                onColorChanged: (value) {
                  pickerColor = value;
                },
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Got it'),
                onPressed: () {
                  _currentColor = pickerColor;
                  _updateBlend();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _pickerMode() {
    FixedExtentScrollController _controller = FixedExtentScrollController(
        initialItem: BlendMode.values.indexOf(_mode));
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick a mode!'),
            content: SizedBox(
              height: 300,
              child: ListWheelScrollView(
                itemExtent: 30,
                useMagnifier: true,
                magnification: 1.3,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                controller: _controller,
                children: BlendMode.values
                    .map<Widget>((item) => Text(item.toString()))
                    .toList(),
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Got it'),
                onPressed: () {
                  _mode = BlendMode.values[_controller.selectedItem];
                  _updateBlend();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotate Image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            const Text('原始图像:'),
            Image(
              image: image!,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                const Text('混合颜色'),
                GestureDetector(
                  onTap: _pickerColor,
                  child: Container(
                    width: 30,
                    height: 30,
                    color: _currentColor,
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: _pickerMode,
                  child: Text("混合模式:" +
                      _mode.toString().replaceFirst('BlendMode.', '')),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            Image(image: rotateImage!),
          ],
        ),
      ),
    );
  }
}
