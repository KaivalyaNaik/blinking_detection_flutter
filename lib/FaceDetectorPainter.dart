import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.absoluteImageSize, this.faces);

  final Size absoluteImageSize;
  final List<Face>? faces;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;
    if (faces != null)
      for (final Face face in faces!) {
        canvas.drawRect(
          Rect.fromLTRB(
            face.boundingBox.left * scaleX,
            face.boundingBox.top * scaleY,
            face.boundingBox.right * scaleX,
            face.boundingBox.bottom * scaleY,
          ),
          paint,
        );
      }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.faces != faces;
  }
}
