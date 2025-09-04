import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'ml_kit_service.dart';

class CloudVisionService {
  final String baseUrl;
  final String apiKey;
  final String provider;
  
  CloudVisionService({
    required this.baseUrl,
    required this.apiKey,
    required this.provider,
  });

  Future<CloudVisionResult> analyzeImage(XFile imageFile) async {
    try {
      switch (provider.toLowerCase()) {
        case 'openai':
          return await _analyzeWithOpenAI(imageFile);
        case 'claude':
          return await _analyzeWithClaude(imageFile);
        case 'google':
          return await _analyzeWithGoogleVision(imageFile);
        default:
          return await _analyzeWithCustomAPI(imageFile);
      }
    } catch (e) {
      throw Exception('Cloud vision analysis failed: $e');
    }
  }

  Future<CloudVisionResult> _analyzeWithOpenAI(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Analyze this image and identify all objects/items visible. For each item, provide: 1) Item name, 2) Confidence level (0-1), 3) Brief description. Focus on products, food items, tools, or any identifiable objects. Return the response as a JSON array with objects containing "label", "confidence", and "description" fields.'
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 1000
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return _parseOpenAIResponse(content);
    } else {
      final errorBody = response.body;
      throw Exception('OpenAI API error: ${response.statusCode} - $errorBody');
    }
  }

  Future<CloudVisionResult> _analyzeWithClaude(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Analyze this image and identify all objects/items visible. For each item, provide: 1) Item name, 2) Confidence level (0-1), 3) Brief description. Focus on products, food items, tools, or any identifiable objects. Return the response as a JSON array with objects containing "label", "confidence", and "description" fields.'
              },
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image
                }
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'];
      return _parseClaudeResponse(content);
    } else {
      throw Exception('Claude API error: ${response.statusCode}');
    }
  }

  Future<CloudVisionResult> _analyzeWithGoogleVision(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('$baseUrl/images:annotate?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'image': {
              'content': base64Image
            },
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _parseGoogleVisionResponse(data);
    } else {
      throw Exception('Google Vision API error: ${response.statusCode}');
    }
  }

  Future<CloudVisionResult> _analyzeWithCustomAPI(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'image': base64Image,
        'features': ['object_detection', 'labeling']
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _parseCustomAPIResponse(data);
    } else {
      throw Exception('Custom API error: ${response.statusCode}');
    }
  }

  CloudVisionResult _parseOpenAIResponse(String content) {
    try {
      // Extract JSON from the response
      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']') + 1;
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = content.substring(jsonStart, jsonEnd);
        final List<dynamic> items = jsonDecode(jsonStr);
        
        return CloudVisionResult(
          items: items.map((item) => CloudDetectedItem(
            label: item['label'] ?? 'Unknown',
            confidence: (item['confidence'] as num?)?.toDouble() ?? 0.8,
            description: item['description'] ?? '',
          )).toList(),
          description: _generateDescription(items),
        );
      }
    } catch (e) {
      // Fallback parsing
    }
    
    return CloudVisionResult(
      items: [
        CloudDetectedItem(
          label: 'General Objects',
          confidence: 0.7,
          description: content,
        )
      ],
      description: content,
    );
  }

  CloudVisionResult _parseClaudeResponse(String content) {
    return _parseOpenAIResponse(content); // Similar parsing logic
  }

  CloudVisionResult _parseGoogleVisionResponse(Map<String, dynamic> data) {
    final List<CloudDetectedItem> items = [];
    
    if (data['responses'] != null && data['responses'].isNotEmpty) {
      final response = data['responses'][0];
      
      // Parse label annotations
      if (response['labelAnnotations'] != null) {
        for (final label in response['labelAnnotations']) {
          items.add(CloudDetectedItem(
            label: label['description'] ?? 'Unknown',
            confidence: (label['score'] as num?)?.toDouble() ?? 0.0,
            description: label['description'] ?? '',
          ));
        }
      }
      
      // Parse object annotations
      if (response['localizedObjectAnnotations'] != null) {
        for (final obj in response['localizedObjectAnnotations']) {
          items.add(CloudDetectedItem(
            label: obj['name'] ?? 'Unknown',
            confidence: (obj['score'] as num?)?.toDouble() ?? 0.0,
            description: obj['name'] ?? '',
          ));
        }
      }
    }
    
    return CloudVisionResult(
      items: items,
      description: _generateDescriptionFromItems(items),
    );
  }

  CloudVisionResult _parseCustomAPIResponse(Map<String, dynamic> data) {
    final List<CloudDetectedItem> items = [];
    
    if (data['objects'] != null) {
      for (final obj in data['objects']) {
        items.add(CloudDetectedItem(
          label: obj['label'] ?? 'Unknown',
          confidence: (obj['confidence'] as num?)?.toDouble() ?? 0.0,
          description: obj['description'] ?? '',
        ));
      }
    }
    
    return CloudVisionResult(
      items: items,
      description: data['description'] ?? _generateDescriptionFromItems(items),
    );
  }

  String _generateDescription(List<dynamic> items) {
    if (items.isEmpty) return 'No items detected';
    
    final labels = items.map((item) => item['label'] as String).join(', ');
    return 'Detected items: $labels';
  }

  String _generateDescriptionFromItems(List<CloudDetectedItem> items) {
    if (items.isEmpty) return 'No items detected';
    
    final labels = items.map((item) => item.label).join(', ');
    return 'Detected items: $labels';
  }
}

class CloudVisionResult {
  final List<CloudDetectedItem> items;
  final String description;

  const CloudVisionResult({
    required this.items,
    required this.description,
  });
}

class CloudDetectedItem {
  final String label;
  final double confidence;
  final String description;

  const CloudDetectedItem({
    required this.label,
    required this.confidence,
    required this.description,
  });

  // Convert to DetectedItem for compatibility with MLKit
  DetectedItem toDetectedItem() {
    return DetectedItem(
      label: label,
      confidence: confidence,
    );
  }
}