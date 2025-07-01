import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:maize_hub/services/ai_service.dart';
import 'package:maize_hub/models/chat_message.dart';
import 'package:maize_hub/theme/app_theme.dart';

class AIAssistanceScreen extends StatefulWidget {
  const AIAssistanceScreen({super.key});

  @override
  State<AIAssistanceScreen> createState() => _AIAssistanceScreenState();
}

class _AIAssistanceScreenState extends State<AIAssistanceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AIService _aiService;

  late final AIConversationState _conversationState;
  late final AnimationController _typingAnimationController;

  // Quick questions state
  bool _showQuickQuestions = true;

  @override
  void initState() {
    super.initState();
    _aiService = AIService.getInstance(); // Use singleton
    _conversationState = AIConversationState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Listen to conversation state changes to manage quick questions
    _conversationState.addListener(_onConversationStateChanged);

    _initializeAI();
  }

  void _onConversationStateChanged() {
    // Hide quick questions after the first user message is sent
    final hasUserMessages = _conversationState.messages.any(
      (message) => message.isUser,
    );

    if (hasUserMessages && _showQuickQuestions) {
      setState(() {
        _showQuickQuestions = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _conversationState.removeListener(_onConversationStateChanged);
    _conversationState.dispose();
    _typingAnimationController.dispose();
    // Don't dispose the AI service as it's a singleton
    super.dispose();
  }

  Future<void> _initializeAI() async {
    try {
      _conversationState.setLoading(true);

      // The AI service is already initialized in main.dart
      // Just ensure it's ready and add welcome message
      if (!_aiService.isInitialized) {
        await _aiService.initialize();
      }

      _conversationState.addWelcomeMessage();
    } catch (e) {
      _conversationState.setError('Failed to initialize AI: $e');
      debugPrint('AI initialization error: $e');
    } finally {
      _conversationState.setLoading(false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _conversationState.isLoading) return;

    // Add user message
    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _conversationState.addMessage(userMessage);
    _messageController.clear();
    _scrollToBottom();

    // Set loading state
    _conversationState.setLoading(true);
    _typingAnimationController.repeat();

    try {
      // Get AI response
      final response = await _aiService.sendMessage(message);

      // Add AI response
      final aiMessage = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _conversationState.addMessage(aiMessage);
      _conversationState.setLoading(false);
      _typingAnimationController.stop();

      // Haptic feedback for successful response
      HapticFeedback.lightImpact();

      // Save conversation to Firestore
      _saveConversationToFirestore(message, response);
    } catch (e) {
      _conversationState.setError('Failed to get response: $e');
      _typingAnimationController.stop();

      // Add error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content:
            'Sorry, I encountered an error. Please try again or rephrase your question.',
        isUser: false,
        timestamp: DateTime.now(),
        status: MessageStatus.error,
      );

      _conversationState.addMessage(errorMessage);
      HapticFeedback.heavyImpact();
    }

    _scrollToBottom();
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

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text(
          'Are you sure you want to clear the entire conversation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _conversationState.clearMessages();
              _aiService.clearHistory();
              setState(() {
                _showQuickQuestions = true; // Show quick questions again
              });
              _conversationState.addWelcomeMessage();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConversationToFirestore(
    String question,
    String response,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ai_conversations')
            .add({
              'question': question,
              'response': response,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      // Silently fail - conversation saving is not critical
      debugPrint('Failed to save conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.chatBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Colors.white),
            SizedBox(width: 8),
            Text('MaizeBot AI Assistant'),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearConversation,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages area - takes up remaining space
            Expanded(
              child: ListenableBuilder(
                listenable: _conversationState,
                builder: (context, _) {
                  if (_conversationState.error != null) {
                    return _buildErrorWidget();
                  }

                  return Column(
                    children: [
                      // Messages list
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              _conversationState.messages.length +
                              (_conversationState.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _conversationState.messages.length) {
                              return _buildMessageBubble(
                                _conversationState.messages[index],
                              );
                            } else {
                              return _buildTypingIndicator();
                            }
                          },
                        ),
                      ),

                      // Quick questions - only show when appropriate
                      if (_showQuickQuestions)
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: _buildQuickQuestions(),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Input area - fixed at bottom
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryGreen,
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Use markdown for AI responses, regular text for user messages
                  if (message.isUser)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        h1: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h3: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        strong: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          color: AppTheme.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        code: TextStyle(
                          backgroundColor: AppTheme.lightGreen,
                          color: AppTheme.darkGreen,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        listBullet: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 16,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: AppTheme.lightGreen,
                          border: Border(
                            left: BorderSide(
                              color: AppTheme.primaryGreen,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                      selectable: true,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white70
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (message.status == MessageStatus.error)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.error_outline,
                            size: 14,
                            color: message.isUser ? Colors.white70 : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentOrange,
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: AppTheme.primaryGreen.withValues(
                            alpha:
                                (0.3 +
                                        0.7 *
                                            (((_typingAnimationController
                                                        .value +
                                                    i * 0.3) %
                                                1.0)))
                                    .clamp(0.0, 1.0),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'MaizeBot is thinking...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      QuickQuestion(
        emoji: '🌱',
        title: 'How do I plant maize?',
        subtitle: 'Planting guide and best practices',
      ),
      QuickQuestion(
        emoji: '💧',
        title: 'When should I water my crops?',
        subtitle: 'Irrigation timing and frequency',
      ),
      QuickQuestion(
        emoji: '🐛',
        title: 'Help me identify a pest problem',
        subtitle: 'Pest identification and treatment',
      ),
      QuickQuestion(
        emoji: '🌾',
        title: 'What fertilizer is best for maize?',
        subtitle: 'Fertilization recommendations',
      ),
      QuickQuestion(
        emoji: '🌤️',
        title: 'Weather advice for farming',
        subtitle: 'Weather-based farming decisions',
      ),
      QuickQuestion(
        emoji: '🚜',
        title: 'When is the best time to harvest?',
        subtitle: 'Harvest timing and storage tips',
      ),
    ];

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quick Questions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showQuickQuestions = false;
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a question to get started, or type your own question below.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3.0, // Increased from 2.5 to give more width
              ),
              itemCount: quickQuestions.length,
              itemBuilder: (context, index) {
                return _buildQuickQuestionCard(quickQuestions[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestionCard(QuickQuestion question) {
    return GestureDetector(
      onTap: () => _selectQuickQuestion(question.title),
      child: Container(
        padding: const EdgeInsets.all(8), // Reduced padding from 12 to 8
        decoration: BoxDecoration(
          color: AppTheme.lightGreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              // Wrap the Row in Expanded
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align to start
                children: [
                  Text(
                    question.emoji,
                    style: const TextStyle(fontSize: 14),
                  ), // Reduced emoji size
                  const SizedBox(width: 6), // Reduced spacing
                  Expanded(
                    child: Text(
                      question.title,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        // Changed to labelSmall
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 11, // Smaller font size
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              question.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 9, // Smaller subtitle font
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _selectQuickQuestion(String question) {
    // Add haptic feedback
    HapticFeedback.selectionClick();

    // Set the question in the text field (for user to see)
    _messageController.text = question;

    // Hide quick questions immediately
    setState(() {
      _showQuickQuestions = false;
    });

    // Send the message after a brief delay to show the text field update
    Future.delayed(const Duration(milliseconds: 200), () {
      _sendMessage();
    });
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Ask MaizeBot anything about farming...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
                splashRadius: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.warningRed),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _conversationState.error ?? 'Unknown error',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _conversationState.setError(null);
              _initializeAI();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('About MaizeBot'),
          ],
        ),
        content: const Text(
          'MaizeBot is your AI-powered farming assistant, specialized in maize cultivation. '
          'Ask questions about planting, care, disease identification, pest control, and more!\n\n'
          'Powered by Google\'s Gemini AI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

/// Model class for quick questions
class QuickQuestion {
  final String emoji;
  final String title;
  final String subtitle;

  const QuickQuestion({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });
}
