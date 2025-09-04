import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/receipt_models.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  Future<bool> testConnection(String apiUrl) async {
    try {
      final uri = Uri.parse(apiUrl);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      return response.statusCode < 500;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<bool> addItem({
    required String itemCode,
    required int quantity,
    required String apiUrl,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/api/transaction/additem');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'itemcode': itemCode,
          'quantity': quantity,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('Invalid request: ${response.body}');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to add item: $e');
    }
  }

  Future<Map<String, dynamic>?> searchItem({
    required String searchTerm,
    required String apiUrl,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/api/items/search?q=${Uri.encodeComponent(searchTerm)}');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Item search failed: $e');
      return null;
    }
  }

  Future<String> sendChatMessage({
    required String message,
    required String apiUrl,
    Map<String, dynamic>? context,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/api/chat');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'context': context,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from AI';
      } else {
        throw Exception('Failed to get AI response');
      }
    } catch (e) {
      throw Exception('Chat API error: $e');
    }
  }

  Future<CurrentReceiptResponse> getCurrentReceipt({
    required String apiUrl,
  }) async {
    try {
      final uri = Uri.parse('$apiUrl/api/receipt/current');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrentReceiptResponse.fromJson(data);
      } else {
        throw Exception('Failed to get current receipt: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network connection failed. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to get current receipt: $e');
    }
  }
}