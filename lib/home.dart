import 'package:camera/camera.dart';
import 'package:emotion_detector/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';

  @override
  void initState() {
    super.initState();
    loadCamera();
    loadmodel();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  loadCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.max);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            runModel();
          });
        });
      }
    });
  }

  runModel() async {
    var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 2,
        threshold: 0.1,
        asynch: true);
    predictions!.forEach((element) {
      setState(() {
        print("Result is: " + element);
        output = element['label'];
      });
    });
  }

  loadmodel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Emotion Detection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 73, 38, 212),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: cameraController!.value.isInitialized
                  ? CameraPreview(
                      cameraController!) // Display CameraPreview if initialized
                  : Center(
                      child:
                          CircularProgressIndicator(), // Show loading indicator while initializing
                    ),
            ),
          ),
          Text(
            output,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          )
        ],
      ),
    );
  }
}
