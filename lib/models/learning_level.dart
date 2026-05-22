import 'package:flutter/material.dart';

class LearningLevel {
  final String id;
  final String title;
  final String subtitle;
  final double progress;
  final bool unlocked;
  final Color accentColor;
  // 점자 셀 2x3: [좌1,좌2,좌3,우1,우2,우3]
  final List<bool> dots;

  const LearningLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.unlocked,
    required this.accentColor,
    required this.dots,
  });

  LearningLevel copyWith({double? progress}) {
    return LearningLevel(
      id: id,
      title: title,
      subtitle: subtitle,
      progress: progress ?? this.progress,
      unlocked: unlocked,
      accentColor: accentColor,
      dots: dots,
    );
  }
}