import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:maize_hub/screens/auth.dart';
import 'package:maize_hub/screens/chart.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Maize Disease Classifier',
      theme: ThemeData().copyWith(
        // green color scheme for maize app
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF81C784),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const ChatScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
 