import 'dart:typed_data';

import 'package:buffer_image/buffer_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class GrayPage extends StatefulWidget {
  const GrayPage({Key? key}) : super(key: key);
  @override
  State<GrayPage> createState() => _GrayPageState();
}

class _GrayPageState extends State<GrayPage> {
  BufferImage? bufferImage;
  GrayImage? grayImage;
  GrayImage? deNoiseImage;
  GrayImage? binaryImage;

  loadFile() async {
    Uint8List? fileData = await _pickFile();

    if (fileData != null) {
      bufferImage = await BufferImage.fromFile(fileData);
      if (bufferImage == null) {
        alert(context, 'Can\'t read the image');
        return;
      }
      grayImage = bufferImage?.toGray();

      deNoiseImage = grayImage!.copy()
        ..deNoise()
        ..binaryzation()
        ..deNoise();

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    loadFile();
                  },
                  child: const Text('file...'),
                ),
              ),
              const SizedBox(height: 20),
              if (bufferImage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image(
                      image: RgbaImage.fromBufferImage(bufferImage!, scale: 1),
                    ),
                  ),
                ),
              if (grayImage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image(
                      image: RgbaImage.fromBufferImage(
                          BufferImage.fromGray(grayImage!),
                          scale: 1),
                    ),
                  ),
                ),
              if (deNoiseImage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image(
                      image: RgbaImage.fromBufferImage(
                          BufferImage.fromGray(deNoiseImage!),
                          scale: 1),
                    ),
                  ),
                ),
              if (binaryImage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image(
                      image: RgbaImage.fromBufferImage(
                          BufferImage.fromGray(binaryImage!),
                          scale: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
