import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final ApiService _apiService = ApiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  ChatProvider(this._databaseService);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  Future<void> loadChatHistory() async {
    final history = await _databaseService.getChatHistory();
    _messages.clear();
    _messages.addAll(history);
    notifyListeners();
  }

  Future<void> sendMessage(String content, String apiUrl, {Map<String, dynamic>? context}) async {
    final userMessage = ChatMessage(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    await _databaseService.saveChatMessage(userMessage);
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.sendChatMessage(
        message: content,
        apiUrl: apiUrl,
        context: context,
      );
      
      final aiResponse = ChatMessage(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(aiResponse);
      await _databaseService.saveChatMessage(aiResponse);
    } catch (e) {
      final errorMessage = ChatMessage(
        content: 'Error: Failed to get AI response. ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    _messages.clear();
    await _databaseService.clearChatHistory();
    notifyListeners();
  }

  void removeMessage(ChatMessage message) {
    _messages.remove(message);
    notifyListeners();
  }
}