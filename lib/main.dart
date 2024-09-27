import 'package:flutter/material.dart';
import 'package:object_detection/home_screen.dart';

void main() {
  runApp(const MyApp());
}

const String ssd = 'SSD MobileNet';
const String yolo = 'Tiny YOLOv2';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: TfliteHome(),
    );
  }
}
