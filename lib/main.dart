import 'package:flutter/material.dart';
import 'services/firebase_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await ThemeController.loadTheme();
  runApp(const TracebackApp());
}

class TracebackApp extends StatelessWidget {
  const TracebackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'Traceback — AI Digital Scam Investigator',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const SplashScreen(),
        );
      },
    );
  }
}
