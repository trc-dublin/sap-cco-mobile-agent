import 'dart:io';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:camera/camera.dart';
import 'cloud_vision_service.dart';

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

  Future<CombinedVisionResult> processImageWithCloud({
    required XFile imageFile,
    bool useCloudVision = false,
    CloudVisionService? cloudService,
  }) async {
    try {
      // Always get local ML Kit results
      final localResults = await processImage(imageFile);
      
      if (!useCloudVision || cloudService == null) {
        return CombinedVisionResult(
          localItems: localResults,
          cloudItems: [],
          combinedItems: localResults,
          description: generateDescription(localResults),
          source: 'Local ML Kit only',
        );
      }

      // Get cloud results
      try {
        final cloudResult = await cloudService.analyzeImage(imageFile);
        final cloudItems = cloudResult.items.map((item) => item.toDetectedItem()).toList();
        
        // Combine and deduplicate results
        final combinedItems = _combineResults(localResults, cloudItems);
        
        return CombinedVisionResult(
          localItems: localResults,
          cloudItems: cloudItems,
          combinedItems: combinedItems,
          description: cloudResult.description.isNotEmpty 
              ? cloudResult.description 
              : generateDescription(combinedItems),
          source: 'ML Kit + Cloud Vision',
        );
      } catch (cloudError) {
        // If cloud fails, fall back to local results
        return CombinedVisionResult(
          localItems: localResults,
          cloudItems: [],
          combinedItems: localResults,
          description: '${generateDescription(localResults)} (Cloud analysis failed)',
          source: 'Local ML Kit (Cloud failed)',
        );
      }
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  List<DetectedItem> _combineResults(
    List<DetectedItem> localItems,
    List<DetectedItem> cloudItems,
  ) {
    final Map<String, DetectedItem> itemMap = {};
    
    // Add local items
    for (final item in localItems) {
      final key = item.label.toLowerCase().trim();
      itemMap[key] = item;
    }
    
    // Add or merge cloud items
    for (final item in cloudItems) {
      final key = item.label.toLowerCase().trim();
      if (itemMap.containsKey(key)) {
        // If item exists, use higher confidence
        final existing = itemMap[key]!;
        if (item.confidence > existing.confidence) {
          itemMap[key] = item;
        }
      } else {
        // Add new item from cloud
        itemMap[key] = item;
      }
    }
    
    // Return sorted by confidence
    final combinedItems = itemMap.values.toList();
    combinedItems.sort((a, b) => b.confidence.compareTo(a.confidence));
    return combinedItems;
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

class CombinedVisionResult {
  final List<DetectedItem> localItems;
  final List<DetectedItem> cloudItems;
  final List<DetectedItem> combinedItems;
  final String description;
  final String source;

  const CombinedVisionResult({
    required this.localItems,
    required this.cloudItems,
    required this.combinedItems,
    required this.description,
    required this.source,
  });
}