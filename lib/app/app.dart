import 'package:flutter/material.dart';
import 'theme.dart';
import '../features/splash/splash_screen.dart';

class FarmlinkApp extends StatelessWidget {
  const FarmlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmlink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
