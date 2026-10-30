/*
 * LookBook application entry point.
 * Author: Ariel Fajimiyo
 * Date: 22/10/26
 */

import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'widgets/in_app_notification_host.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LookBookApp());
}

class LookBookApp extends StatelessWidget {
  const LookBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LookBook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B2432),
          primary: const Color(0xFF1B2432),
          surface: const Color(0xFFFAFAF8),
        ),
      ),
builder: (context, child) {
  return SizedBox.expand(
    child: InAppNotificationHost(
      child: child ?? const SizedBox.shrink(),
    ),
  );
},
      home: const WelcomeScreen(),
    );
  }
}