import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  void onPressed() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: onPressed,
          ),
        ],
        title: const Text('Chat Screen'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Chat Screen!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
