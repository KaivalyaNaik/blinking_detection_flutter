import 'dart:math';

import 'package:blinking_detection/FaceDetectorPainter.dart';
import 'package:blinking_detection/ScannerUtils.dart';
import 'package:blinking_detection/Success.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class BlinkDetection extends StatefulWidget {
  final CameraDescription camera;
  const BlinkDetection({required this.camera});
  @override
  _BlinkDetectionState createState() => _BlinkDetectionState();
}

class _BlinkDetectionState extends State<BlinkDetection> {
  late CameraController cameraController;
  late Future<void> _initializeControllerFuture;
  dynamic _scanResults;
  bool _isDetecting = false;
  int state = 0;
  static const double OPEN_THRESHOLD = 0.85;
  static const double CLOSE_THRESHOLD = 0.1;

  final FaceDetector faceDetector = GoogleVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: true,
          enableTracking: true,
          enableLandmarks: true,
          mode: FaceDetectorMode.accurate));
  @override
  void initState() {
    super.initState();
    cameraController =
        CameraController(widget.camera, ResolutionPreset.veryHigh);
    _initializeControllerFuture = cameraController.initialize().then((_) async {
      await cameraController.startImageStream((CameraImage image) {
        if (_isDetecting) return;

        _isDetecting = true;

        ScannerUtils.detect(
                image: image,
                detectInImage: faceDetector.processImage,
                imageRotation: widget.camera.sensorOrientation)
            .then((dynamic results) {
          if (!mounted) return;
          setState(() {
            _scanResults = results;
          });
        }).whenComplete(() => _isDetecting = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildImage(),
    );
  }

  Widget _buildResults() {
    const Text noResultsText = Text("No Results !");

    if (_scanResults == null ||
        !cameraController.value.isInitialized ||
        _scanResults.isEmpty) {
      return noResultsText;
    }
    Face? face;
    face = _scanResults[0];
    if (face == null) return noResultsText;
    onUpdate(face);

    CustomPainter painter;
    final Size imageSize = Size(cameraController.value.previewSize!.height,
        cameraController.value.previewSize!.width);

    if (_scanResults is! List<Face>) return noResultsText;
    painter = FaceDetectorPainter(imageSize, _scanResults);
    return CustomPaint(painter: painter);
  }

  Widget _buildImage() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    return Container(
      constraints: const BoxConstraints.expand(),
      child: cameraController == null
          ? const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(cameraController),
                _buildResults(),
              ],
            ),
    );
  }

  void onUpdate(Face? face) {
    double? left = face?.leftEyeOpenProbability;
    double? right = face?.rightEyeOpenProbability;

    if (left != null && right != null) {
      blink(min(left, right));
    }
  }

  void blink(double value) {
    switch (state) {
      case 0:
        if (value > OPEN_THRESHOLD) {
          state = 1;
        }
        break;
      case 1:
        if (value < CLOSE_THRESHOLD) {
          state = 2;
        }
        break;
      case 2:
        if (value > OPEN_THRESHOLD) {
          state = 0;
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SuccessPage()));
        }
    }
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    cameraController.dispose().then((_) => {faceDetector.close()});
    super.dispose();
  }
}
