import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:maize_hub/theme/app_theme.dart';

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatelessWidget {
  // Create a message bubble which is meant to be the first in the sequence.
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.messageStatus,
    required this.isUserOnline,
    this.readBy = const [],
  }) : isFirstInSequence = true;

  // Create a message bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.messageStatus,
    required this.isUserOnline,
    this.readBy = const [],
  }) : isFirstInSequence = false,
       userImage = null,
       username = null;

  // Whether or not this message bubble is the first in a sequence of messages
  // from the same user.
  // Modifies the message bubble slightly for these different cases - only
  // shows user image for the first message from the same user, and changes
  // the shape of the bubble for messages thereafter.
  final bool isFirstInSequence;

  // Image of the user to be displayed next to the bubble.
  // Not required if the message is not the first in a sequence.
  final String? userImage;

  // Username of the user.
  // Not required if the message is not the first in a sequence.
  final String? username;
  final String message;

  // Controls how the MessageBubble will be aligned.
  final bool isMe;

  // Message timestamp
  final Timestamp timestamp;

  // Message status (sent, delivered, read)
  final String messageStatus;

  // Whether the user is currently online
  final bool isUserOnline;

  // List of user IDs who have read this message
  final List<String> readBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users (left side)
          if (!isMe && isFirstInSequence) _buildAvatar(theme),
          if (!isMe && !isFirstInSequence) const SizedBox(width: 48),

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Username and online status
                if (isFirstInSequence && !isMe) _buildUserInfo(theme),

                // Message bubble
                Container(
                  decoration: _getMessageDecoration(),
                  padding: ChatTheme.messagePadding,
                  margin: ChatTheme.messageMargin,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        message,
                        style: TextStyle(
                          color: isMe ? Colors.white : AppTheme.textPrimary,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Timestamp and status
                      _buildMessageFooter(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Avatar for current user (right side)
          if (isMe && isFirstInSequence) _buildAvatar(theme),
          if (isMe && !isFirstInSequence) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(left: isMe ? 8 : 0, right: isMe ? 0 : 8),
      child: Stack(
        children: [
          CircleAvatar(
            radius: ChatTheme.avatarRadius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: userImage != null
                ? NetworkImage(userImage!)
                : null,
            child: userImage == null
                ? Icon(Icons.person, color: theme.colorScheme.primary, size: 24)
                : null,
          ),
          // Online indicator
          if (isUserOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.onlineIndicator,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 4),
      child: Row(
        children: [
          Text(
            username ?? 'Unknown User',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          if (isUserOnline) ...[
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.onlineIndicator,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'online',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.onlineIndicator,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageFooter(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: isMe ? Colors.white70 : AppTheme.messageStatus,
            fontSize: 11,
          ),
        ),
        if (isMe) ...[const SizedBox(width: 6), _buildStatusIcon()],
      ],
    );
  }

  BoxDecoration _getMessageDecoration() {
    if (isMe) {
      return isFirstInSequence
          ? ChatTheme.myMessageDecoration
          : ChatTheme.continuingMyMessageDecoration;
    } else {
      return isFirstInSequence
          ? ChatTheme.otherMessageDecoration
          : ChatTheme.continuingOtherMessageDecoration;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  Widget _buildStatusIcon() {
    switch (messageStatus) {
      case 'sent':
        return Icon(Icons.check, size: 14, color: Colors.white70);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: Colors.white70);
      case 'read':
        return Icon(
          Icons.done_all,
          size: 14,
          color: AppTheme.messageStatusRead,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
