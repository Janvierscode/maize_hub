import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:maize_hub/widgets/message_bubble.dart';
import 'package:maize_hub/services/user_presence_service.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  // Constants for better maintainability
  static const double _listPadding = 40.0;
  static const double _cacheExtent = 1000.0;
  static const double _iconSize = 48.0;
  static const double _spacing = 16.0;
  static const double _smallSpacing = 8.0;
  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: _iconSize,
                ),
                const SizedBox(height: _spacing),
                const Text(
                  'Unable to load messages',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: _smallSpacing),
                const Text(
                  'Please check your connection and try again',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _spacing),
                ElevatedButton(
                  onPressed: () {
                    // Trigger a rebuild to retry
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: _iconSize,
                  color: Colors.grey,
                ),
                SizedBox(height: _spacing),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  'Start a conversation!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: _listPadding,
            left: 8,
            right: 8,
            top: 16,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          // Performance optimization: only build visible items
          cacheExtent: _cacheExtent, // Cache more items for smoother scrolling
          itemBuilder: (context, index) {
            try {
              return _buildMessageItem(
                loadedMessages,
                index,
                authenticatedUser,
              );
            } catch (e) {
              // If there's an error with a specific message, just skip it
              debugPrint('Error building message at index $index: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  /// Builds individual message items with proper error handling
  /// and data validation. Determines whether to show first or next
  /// message bubble based on user sequence.
  Widget _buildMessageItem(
    List<QueryDocumentSnapshot> loadedMessages,
    int index,
    User authenticatedUser,
  ) {
    final chatMessage = loadedMessages[index].data() as Map<String, dynamic>;
    final nextChatMessage = index + 1 < loadedMessages.length
        ? loadedMessages[index + 1].data() as Map<String, dynamic>
        : null;

    // Safely extract required fields
    final messageText = chatMessage['text']?.toString() ?? '';
    final messageUserId = chatMessage['userId']?.toString() ?? '';
    final messageTimestamp = chatMessage['createdAt'] as Timestamp?;

    // Skip message if essential data is missing
    if (messageText.isEmpty ||
        messageUserId.isEmpty ||
        messageTimestamp == null) {
      return const SizedBox.shrink();
    }

    final nextMessageUserId = nextChatMessage != null
        ? nextChatMessage['userId']?.toString() ?? ''
        : '';
    final nextUserIsSame = nextMessageUserId == messageUserId;

    // Extract optional fields with defaults
    final messageStatus = chatMessage['status']?.toString() ?? 'sent';
    final userImage = chatMessage['userImage']?.toString();
    final username = chatMessage['username']?.toString();
    final readByRaw = chatMessage['readBy'] ?? [];
    final readBy = readByRaw is List
        ? readByRaw.map((e) => e.toString()).toList()
        : <String>[];

    final isMe = authenticatedUser.uid == messageUserId;

    if (nextUserIsSame) {
      return _buildMessageBubbleNext(
        messageText,
        isMe,
        messageTimestamp,
        messageStatus,
        readBy,
        messageUserId,
      );
    } else {
      return _buildMessageBubbleFirst(
        userImage,
        username,
        messageText,
        isMe,
        messageTimestamp,
        messageStatus,
        readBy,
        messageUserId,
      );
    }
  }

  /// Builds a continuing message bubble with online status
  Widget _buildMessageBubbleNext(
    String messageText,
    bool isMe,
    Timestamp messageTimestamp,
    String messageStatus,
    List<String> readBy,
    String messageUserId,
  ) {
    if (isMe) {
      // For current user messages, no need to check online status
      return MessageBubble.next(
        message: messageText,
        isMe: isMe,
        timestamp: messageTimestamp,
        messageStatus: messageStatus,
        isUserOnline: false,
        readBy: readBy,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: UserPresenceService.getUserPresence(messageUserId),
      builder: (context, userSnapshot) {
        final isUserOnline =
            userSnapshot.hasData &&
            userSnapshot.data!.exists &&
            (userSnapshot.data!.data() as Map<String, dynamic>?)?['isOnline'] ==
                true;

        return MessageBubble.next(
          message: messageText,
          isMe: isMe,
          timestamp: messageTimestamp,
          messageStatus: messageStatus,
          isUserOnline: isUserOnline,
          readBy: readBy,
        );
      },
    );
  }

  /// Builds a first message bubble with online status
  Widget _buildMessageBubbleFirst(
    String? userImage,
    String? username,
    String messageText,
    bool isMe,
    Timestamp messageTimestamp,
    String messageStatus,
    List<String> readBy,
    String messageUserId,
  ) {
    if (isMe) {
      // For current user messages, no need to check online status
      return MessageBubble.first(
        userImage: userImage,
        username: username,
        message: messageText,
        isMe: isMe,
        timestamp: messageTimestamp,
        messageStatus: messageStatus,
        isUserOnline: false,
        readBy: readBy,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: UserPresenceService.getUserPresence(messageUserId),
      builder: (context, userSnapshot) {
        final isUserOnline =
            userSnapshot.hasData &&
            userSnapshot.data!.exists &&
            (userSnapshot.data!.data() as Map<String, dynamic>?)?['isOnline'] ==
                true;

        return MessageBubble.first(
          userImage: userImage,
          username: username,
          message: messageText,
          isMe: isMe,
          timestamp: messageTimestamp,
          messageStatus: messageStatus,
          isUserOnline: isUserOnline,
          readBy: readBy,
        );
      },
    );
  }
}
