import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIAssistanceScreen extends StatefulWidget {
  const AIAssistanceScreen({super.key});

  @override
  State<AIAssistanceScreen> createState() => _AIAssistanceScreenState();
}

class _AIAssistanceScreenState extends State<AIAssistanceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadWelcomeMessage();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _loadWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! 👋 I'm your AI farming assistant. I can help you with:\n\n"
              "🌽 Maize disease identification\n"
              "🌱 Crop management advice\n"
              "💧 Irrigation recommendations\n"
              "🐛 Pest control strategies\n"
              "🌾 Fertilizer guidance\n\n"
              "What would you like to know about your maize crops?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: question, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });

    _questionController.clear();
    _scrollToBottom();
    _typingAnimationController.repeat();

    // Simulate AI response
    await Future.delayed(const Duration(seconds: 2));

    final response = _generateAIResponse(question);

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(text: response, isUser: false, timestamp: DateTime.now()),
      );
    });

    _typingAnimationController.stop();
    _scrollToBottom();

    // TODO: Save conversation to Firestore
    _saveConversation(question, response);
  }

  String _generateAIResponse(String question) {
    final lowerQuestion = question.toLowerCase();

    if (lowerQuestion.contains('disease') ||
        lowerQuestion.contains('sick') ||
        lowerQuestion.contains('spot')) {
      return "🔍 For disease identification, I recommend:\n\n"
          "1. Take clear photos of affected leaves\n"
          "2. Look for specific symptoms:\n"
          "   • Spots or lesions\n"
          "   • Color changes\n"
          "   • Wilting patterns\n\n"
          "3. Use our scanner feature for instant analysis\n"
          "4. Common maize diseases include:\n"
          "   • Common Rust (orange pustules)\n"
          "   • Northern Corn Leaf Blight (gray lesions)\n"
          "   • Gray Leaf Spot (rectangular spots)\n\n"
          "Would you like specific treatment recommendations?";
    }

    if (lowerQuestion.contains('water') || lowerQuestion.contains('irrigat')) {
      return "💧 Maize irrigation guidelines:\n\n"
          "• **Critical periods**: Tasseling and grain filling\n"
          "• **Frequency**: Every 7-10 days (adjust for rainfall)\n"
          "• **Amount**: 25-30mm per week\n"
          "• **Method**: Drip irrigation is most efficient\n\n"
          "**Signs of water stress:**\n"
          "- Leaves curl inward\n"
          "- Stunted growth\n"
          "- Premature tasseling\n\n"
          "Monitor soil moisture at 15-20cm depth. Would you like season-specific advice?";
    }

    if (lowerQuestion.contains('fertil') || lowerQuestion.contains('nutri')) {
      return "🌱 Maize fertilization program:\n\n"
          "**Base application (planting):**\n"
          "• NPK 15:15:15 at 200kg/ha\n\n"
          "**Top dressing (6-8 weeks):**\n"
          "• Urea (46% N) at 100kg/ha\n\n"
          "**Key nutrients:**\n"
          "• Nitrogen: Critical for leaf development\n"
          "• Phosphorus: Root development\n"
          "• Potassium: Disease resistance\n\n"
          "**Deficiency signs:**\n"
          "• N: Yellow lower leaves\n"
          "• P: Purple leaf edges\n"
          "• K: Brown leaf margins\n\n"
          "Need soil test recommendations?";
    }

    if (lowerQuestion.contains('pest') || lowerQuestion.contains('insect')) {
      return "🐛 Common maize pests and control:\n\n"
          "**Fall Armyworm:**\n"
          "• Spray with Bt-based insecticides\n"
          "• Apply in evening hours\n\n"
          "**Stem Borers:**\n"
          "• Use pheromone traps\n"
          "• Plant push-pull crops (Napier grass)\n\n"
          "**Cutworms:**\n"
          "• Apply soil insecticides\n"
          "• Use collar protection for seedlings\n\n"
          "**Integrated approach:**\n"
          "• Crop rotation\n"
          "• Beneficial insects\n"
          "• Resistant varieties\n\n"
          "Which specific pest are you dealing with?";
    }

    if (lowerQuestion.contains('plant') || lowerQuestion.contains('seed')) {
      return "🌱 Maize planting best practices:\n\n"
          "**Timing:**\n"
          "• Plant after last frost date\n"
          "• Soil temperature >10°C\n\n"
          "**Spacing:**\n"
          "• Row spacing: 75cm\n"
          "• Plant spacing: 25cm\n"
          "• Population: 53,000 plants/ha\n\n"
          "**Seed preparation:**\n"
          "• Use certified seeds\n"
          "• Treat with fungicide\n"
          "• Plant 2-3cm deep\n\n"
          "**Field preparation:**\n"
          "• Deep plowing\n"
          "• Proper drainage\n"
          "• Soil pH 6.0-7.0\n\n"
          "Need variety recommendations for your area?";
    }

    // Default response
    return "🤔 That's an interesting question about maize farming! While I try to provide helpful advice, I recommend:\n\n"
        "1. **Consult local agricultural experts** for region-specific guidance\n"
        "2. **Use our disease scanner** for visual plant health assessment\n"
        "3. **Connect with other farmers** in our community chat\n"
        "4. **Contact extension services** in your area\n\n"
        "Could you provide more specific details about your maize farming challenge? For example:\n"
        "• What symptoms are you seeing?\n"
        "• What stage is your crop in?\n"
        "• What's your local growing environment like?\n\n"
        "This will help me give you more targeted advice! 🌽";
  }

  void _saveConversation(String question, String response) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('ai_conversations').add({
          'userId': user.uid,
          'question': question,
          'response': response,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving conversation: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show conversation history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildQuickQuestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser)
              Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            if (!message.isUser) const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final value = (_typingAnimationController.value - delay)
                        .clamp(0.0, 1.0);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5 + 0.5 * value),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      '🌽 Disease identification',
      '💧 Watering schedule',
      '🌱 Fertilizer advice',
      '🐛 Pest control',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickQuestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              quickQuestions[index],
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () {
              _questionController.text = quickQuestions[index].substring(
                2,
              ); // Remove emoji
              _sendMessage();
            },
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Ask about your maize crops...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
