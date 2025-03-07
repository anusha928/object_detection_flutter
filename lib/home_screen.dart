import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_detection/main.dart';
import 'package:tflite/tflite.dart';

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  final String _model = yolo;
  File? _image;
  double? _imageWidth;
  double? _imageHeight;
  bool _busy = false;
  final ImagePicker _picker = ImagePicker();
  List? _recognitions;

  @override
  void initState() {
    super.initState();
    _busy = true;
    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  Future<void> loadModel() async {
    Tflite.close();
    try {
      String? res;
      if (_model == "YOLOv2") {
        res = await Tflite.loadModel(
          model: "assets/tflite/yolov2_tiny.tflite",
          labels: "assets/tflite/yolov2_tiny.txt",
        );
      } else if (_model == "YOLOv5") {
        res = await Tflite.loadModel(
          model: "assets/tflite/yolov5s.tflite",
          labels: "assets/tflite/yolov5s.txt",
        );
      } else {
        res = await Tflite.loadModel(
          model: "assets/tflite/ssd_mobilenet.tflite",
          labels: "assets/tflite/ssd_mobilenet.txt",
        );
      }
      print("Model loaded: $res");
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  Future<void> selectFromImagePicker() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    final fileImage = File(image.path);
    predictImage(fileImage);
  }

  Future<void> predictImage(File image) async {
    if (_model == "YOLOv2" || _model == "YOLOv5") {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }

    FileImage(image)
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageWidth = info.image.width.toDouble();
        _imageHeight = info.image.height.toDouble();
      });
    }));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  Future<void> yolov2Tiny(File image) async {
    try {
      var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1,
      );
      print(recognitions);
      setState(() {
        _recognitions = recognitions;
      });
    } catch (e) {
      print("Error during YOLO detection: $e");
    }
  }

  Future<void> ssdMobileNet(File image) async {
    try {
      var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        numResultsPerClass: 1,
      );
      if (recognitions != null) {
        setState(() {
          _recognitions = recognitions;
          print("Recognitions: $_recognitions");
        });
      } else {
        print("No recognitions found.");
      }
    } catch (e) {
      print("Error in detection: $e");
    }
  }

  List<Widget> renderBoxes(Size screen) {
    if (_recognitions == null || _imageWidth == null || _imageHeight == null)
      return [];
    double factorX = screen.width;
    double factorY = _imageHeight! / _imageHeight! * screen.width;
    Color blue = Colors.blue;
    return _recognitions!.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
            color: blue,
            width: 3,
          )),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 30,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null
          ? const Text("No Image Selected")
          : Image.file(_image!),
    ));

    stackChildren.addAll(renderBoxes(size));

    if (_busy) {
      stackChildren.add(const Center(
        child: CircularProgressIndicator(),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("TFLite Demo"),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Pick Image from gallery",
        onPressed: selectFromImagePicker,
        child: const Icon(Icons.image),
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
