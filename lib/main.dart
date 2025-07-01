import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:maize_hub/screens/auth.dart';
import 'package:maize_hub/widgets/main_navigation.dart';
import 'package:maize_hub/theme/app_theme.dart';
import 'package:maize_hub/services/ai_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize AI service once at app startup
  try {
    final aiService = AIService.getInstance();
    await aiService.initialize();
    debugPrint('AI Service initialized successfully');
  } catch (e) {
    debugPrint('AI Service initialization failed: $e');
    // Continue without AI service - will be handled gracefully in the UI
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maize Hub',
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
