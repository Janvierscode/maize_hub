import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:maize_hub/widgets/chat_messages.dart';
import 'package:maize_hub/widgets/new_message.dart';
import 'package:maize_hub/services/user_presence_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    fcm.subscribeToTopic('chat');
  }

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
    // Set user as online when entering chat
    UserPresenceService.setUserOnline();
  }

  @override
  void dispose() {
    // Set user as offline when leaving chat
    UserPresenceService.setUserOffline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showChatInfo(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ChatMessages()),
          const NewMessage(),
        ],
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Community Guidelines'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🌽 Share farming experiences'),
              SizedBox(height: 8),
              Text('🤝 Help fellow farmers'),
              SizedBox(height: 8),
              Text('📸 Share crop photos for advice'),
              SizedBox(height: 8),
              Text('🚫 Keep it respectful and relevant'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }
}
