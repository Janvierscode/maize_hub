import 'package:flutter/material.dart';

/// Represents a message in the AI chat conversation
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
}

enum MessageStatus { sending, sent, error }

enum MessageType { text, image, system }

/// State management for AI chat
class AIConversationState extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessages => _messages.isNotEmpty;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _error = null;
    notifyListeners();
  }

  void updateMessage(String id, ChatMessage updatedMessage) {
    final index = _messages.indexWhere((msg) => msg.id == id);
    if (index != -1) {
      _messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: '''🌽 **Welcome to MaizeBot!**

I'm your AI farming assistant specializing in maize cultivation. I can help you with:

• **Disease Identification** - Describe symptoms or upload photos
• **Crop Management** - Planting, fertilizing, and care tips
• **Pest Control** - Identify and treat common pests
• **Weather Advice** - Irrigation and weather-related decisions
• **Harvest Guidance** - Optimal timing and storage methods

How can I assist you with your maize farming today?''',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.system,
    );

    addMessage(welcomeMessage);
  }
}
