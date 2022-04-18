import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class ScaleDownPage extends StatefulWidget {
  const ScaleDownPage({Key? key}) : super(key: key);
  @override
  State<ScaleDownPage> createState() => _ScaleDownPageState();
}

class _ScaleDownPageState extends State<ScaleDownPage> {
  BufferImage? bufferImage;
  GrayImage? grayImage;
  BufferImage? downImage;
  GrayImage? grayDownImage;

  loadFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      bufferImage = await BufferImage.fromFile(fileData);
      if (bufferImage == null) {
        alert(context, 'Can\'t read the image');
        return;
      }
      grayImage = bufferImage?.toGray();
      downImage = bufferImage!.copy()..scaleDown(2.5);

      grayDownImage = grayImage!.copy()..scaleDown(2.5);
      setState(() {});
    } else {
      print('not pick any file');
    }
  }

  Future<Uint8List?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null && result.count > 0) {
      return result.files.first.bytes;
    } else {
      // User canceled the picker
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gray Image'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  loadFile();
                },
                child: const Text('file...'),
              ),
              const SizedBox(height: 20),
              if (bufferImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(bufferImage!, scale: 1),
                  ),
                ),
              if (downImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(downImage!, scale: 1),
                  ),
                ),
              if (grayImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                        BufferImage.fromGray(grayImage!),
                        scale: 1),
                  ),
                ),
              if (grayDownImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image(
                    image: RgbaImage.fromBufferImage(
                        BufferImage.fromGray(grayDownImage!),
                        scale: 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
