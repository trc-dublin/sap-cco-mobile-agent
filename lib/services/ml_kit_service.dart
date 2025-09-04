import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:camera/camera.dart';

class MLKitService {
  late ImageLabeler _imageLabeler;
  
  MLKitService() {
    _imageLabeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.7),
    );
  }

  Future<List<DetectedItem>> processImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final labels = await _imageLabeler.processImage(inputImage);
      
      return labels.map((label) => DetectedItem(
        label: label.label,
        confidence: label.confidence,
      )).toList();
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  String generateDescription(List<DetectedItem> items) {
    if (items.isEmpty) {
      return 'No items detected in the image.';
    }

    final sortedItems = items
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

    if (sortedItems.length == 1) {
      return 'Detected: ${sortedItems.first.label}';
    } else if (sortedItems.length <= 3) {
      final labels = sortedItems.map((item) => item.label).join(', ');
      return 'Detected items: $labels';
    } else {
      final topThree = sortedItems.take(3).map((item) => item.label).join(', ');
      final remaining = sortedItems.length - 3;
      return 'Main items detected: $topThree and $remaining more items';
    }
  }

  void dispose() {
    _imageLabeler.close();
  }
}

class DetectedItem {
  final String label;
  final double confidence;

  const DetectedItem({
    required this.label,
    required this.confidence,
  });

  String get confidencePercentage => '${(confidence * 100).toInt()}%';
}