import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maize_hub/models/chat_message.dart';
import 'package:maize_hub/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Widget for displaying individual chat messages
class ChatMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const ChatMessageWidget({super.key, required this.message, this.onRetry});

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: widget.message.isUser
              ? const Offset(0.3, 0.0)
              : const Offset(-0.3, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildMessageContent(),
          ),
        );
      },
    );
  }

  Widget _buildMessageContent() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.message.isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(child: _buildMessageBubble()),
          const SizedBox(width: 8),
          if (widget.message.isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? AppTheme.primaryGreen
            : AppTheme.accentBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        widget.message.isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: widget.message.isUser
            ? AppTheme.primaryGreen
            : AppTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(widget.message.isUser ? 16 : 4),
          bottomRight: Radius.circular(widget.message.isUser ? 4 : 16),
        ),
        border: widget.message.isUser
            ? null
            : Border.all(color: AppTheme.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(),
          const SizedBox(height: 4),
          _buildMessageFooter(),
        ],
      ),
    );
  }

  Widget _buildMessageText() {
    return SelectableText(
      widget.message.content,
      style: TextStyle(
        color: widget.message.isUser ? Colors.white : AppTheme.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
      },
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(widget.message.timestamp),
          style: TextStyle(
            color: widget.message.isUser
                ? Colors.white70
                : AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        if (widget.message.status == MessageStatus.error) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onRetry,
            child: Icon(
              Icons.refresh,
              size: 16,
              color: widget.message.isUser
                  ? Colors.white70
                  : AppTheme.warningRed,
            ),
          ),
        ],
        if (widget.message.status == MessageStatus.sending) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.message.isUser ? Colors.white70 : AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    } else if (difference.inHours > 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

/// Typing indicator widget
class TypingIndicatorWidget extends StatefulWidget {
  const TypingIndicatorWidget({super.key});

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.2,
            0.6 + index * 0.2,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MaizeBot is typing',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _dotAnimations[index],
                      builder: (context, child) {
                        return Container(
                          margin: const EdgeInsets.only(right: 4),
                          child: Opacity(
                            opacity: _dotAnimations[index].value,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
