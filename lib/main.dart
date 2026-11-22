import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const TracebackApp());
}

class TracebackApp extends StatelessWidget {
  const TracebackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Traceback — AI Digital Scam Investigator',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const SplashScreen(),
    );
  }
}
