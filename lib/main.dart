import 'package:flutter/material.dart';
import 'package:puzzle_dot/screens/home_screen.dart';
import 'package:puzzle_dot/theme.dart';

void main() {
  runApp(const PuzzleDotApp());
}

class PuzzleDotApp extends StatelessWidget {
  const PuzzleDotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PuzzleDot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigationScreen(),
    );
  }
}
