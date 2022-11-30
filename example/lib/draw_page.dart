import 'package:buffer_image/buffer_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({Key? key}) : super(key: key);

  @override
  State<DrawPage> createState() => _BlendPageState();
}

class _BlendPageState extends State<DrawPage>
    with AutomaticKeepAliveClientMixin {
  late BufferImage bufferImage;
  TextEditingController sizeController = TextEditingController(text: '14');

  RgbaImage? image;
  RgbaImage? blendImage;
  RgbaImage? iconImage;

  Color _color = Colors.blueAccent;
  BlendMode _mode = BlendMode.src;
  double size = 14;
  IconData icon = Icons.camera;

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

    _updateImage();
    _updateIconImage();
  }

  Future<void> _updateImage() async {
    var buffer = bufferImage.copy();
    buffer.drawRect(const Rect.fromLTWH(10, 20, 40, 30), _color, _mode);
    blendImage = RgbaImage.fromBufferImage(buffer, scale: 1);
    setState(() {});
  }

  Future<void> _updateIconImage() async {
    var buffer = bufferImage.copy();
    await buffer.drawIcon(icon, size,
        Offset(buffer.width - size - 8, buffer.height - size - 8), Colors.blue);
    iconImage = RgbaImage.fromBufferImage(buffer, scale: 1);
    setState(() {});
  }

  void _pickerColor() {
    Color pickerColor = _color;
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
                  _color = pickerColor;
                  _updateImage();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  void _pickerMode() {
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
                  _updateImage();
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
                const Text('方块颜色'),
                GestureDetector(
                  onTap: _pickerColor,
                  child: Container(
                    width: 30,
                    height: 30,
                    color: _color,
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
            Image(
              image: blendImage!,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                const Text('图标'),
                SizedBox(
                  width: 80,
                  child: DropdownButton<IconData>(
                      value: Icons.camera,
                      items: const [
                        DropdownMenuItem(
                          value: Icons.camera,
                          child: Text('camera'),
                        ),
                        DropdownMenuItem(
                          value: Icons.home,
                          child: Text('home'),
                        ),
                        DropdownMenuItem(
                          value: Icons.ac_unit,
                          child: Text('ac_unit'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          icon = v;
                        });
                        _updateIconImage();
                      }),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: sizeController,
                    onChanged: (String v) {
                      if (v.isEmpty) return;
                      final newSize = double.tryParse(v);
                      if (newSize != null && newSize > 0) {
                        size = newSize;
                        _updateIconImage();
                      } else {
                        sizeController.text = size.toString();
                      }
                    },
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixText: '尺寸',
                    ),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 20),
            if (iconImage != null)
              Image(
                image: iconImage!,
              ),
          ],
        ),
      ),
    );
  }
}
