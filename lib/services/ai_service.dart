import 'package:firebase_ai/firebase_ai.dart';

/// Service class for handling AI conversations with Firebase AI (Gemini)
class AIService {
  static AIService? _instance;
  static bool _isCreatingInstance = false;

  AIService._internal();

  static AIService getInstance() {
    if (_instance == null && !_isCreatingInstance) {
      _isCreatingInstance = true;
      _instance = AIService._internal();
      _isCreatingInstance = false;
    }
    return _instance!;
  }

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the AI service with Gemini model
  Future<void> initialize() async {
    // Prevent multiple simultaneous initializations
    if (_isInitialized || _isInitializing) {
      // Wait for existing initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;

    try {
      // Only initialize if not already initialized
      if (!_isInitialized) {
        _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash-exp',
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
            maxOutputTokens: 1024,
          ),
          systemInstruction: Content.system(_getSystemPrompt()),
          safetySettings: [
            SafetySetting(
              HarmCategory.dangerousContent,
              HarmBlockThreshold.medium,
              null,
            ),
            SafetySetting(
              HarmCategory.harassment,
              HarmBlockThreshold.medium,
              null,
            ),
            SafetySetting(
              HarmCategory.hateSpeech,
              HarmBlockThreshold.medium,
              null,
            ),
            SafetySetting(
              HarmCategory.sexuallyExplicit,
              HarmBlockThreshold.medium,
              null,
            ),
          ],
        );

        _chatSession = _model!.startChat();
        _isInitialized = true;
      }
    } catch (e) {
      _isInitialized = false;
      throw AIServiceException('Failed to initialize AI service: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Get system prompt for maize farming assistance
  String _getSystemPrompt() {
    return '''
You are MaizeBot, an expert AI assistant specializing in maize (corn) farming and agriculture.
Your role is to provide accurate, helpful, and practical advice to farmers about:

1. Maize disease identification and treatment
2. Crop management and best practices
3. Irrigation and water management
4. Pest and weed control
5. Soil health and fertilization
6. Harvest timing and storage
7. Weather-related farming decisions
8. Sustainable farming practices

Guidelines:
- Always provide practical, actionable advice
- Ask clarifying questions when needed
- Use simple, farmer-friendly language
- Include specific product names or techniques when helpful
- Emphasize safety and environmental considerations
- If unsure, recommend consulting local agricultural experts
- Keep responses concise but comprehensive
- Use emojis sparingly to make responses friendly

Remember: You're helping real farmers make important decisions about their crops and livelihood.
''';
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_chatSession == null) {
      throw AIServiceException('Chat session not initialized');
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      print(response);

      if (response.text == null || response.text!.isEmpty) {
        throw AIServiceException('Empty response from AI');
      }

      return response.text!;
    } catch (e) {
      if (e is FirebaseAIException) {
        throw AIServiceException('AI Error: ${e.message}');
      }
      throw AIServiceException('Failed to send message: $e');
    }
  }

  /// Get conversation history
  List<Content> getHistory() {
    return _chatSession?.history.toList() ?? [];
  }

  /// Clear conversation history and start fresh
  void clearHistory() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Dispose resources
  void dispose() {
    _chatSession = null;
    _isInitialized = false;
  }
}

/// Custom exception for AI service errors
class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
