import 'package:flutter/material.dart';

import '../screens/level_detail_screen.dart';
import '../screens/settings_screen.dart';

class ChatbotService {
  static Future<bool> handleMessage(
    String message,
    BuildContext context,
  ) async {
    final normalized = message.toLowerCase();

    if (normalized.contains('입문')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: '1',
            stageTitle: '입문',
            stageDescription: '처음 시작하는 학습자를 위한 입문 단계입니다.',
          ),
        ),
      );
      return true;
    }
    if (normalized.contains('초급')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: '2',
            stageTitle: '초급',
            stageDescription: '기본 개념을 다지는 초급 단계입니다.',
          ),
        ),
      );
      return true;
    }
    if (normalized.contains('중급')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: '3',
            stageTitle: '중급',
            stageDescription: '응용과 반복 학습이 필요한 중급 단계입니다.',
          ),
        ),
      );
      return true;
    }
    if (normalized.contains('고급')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: '4',
            stageTitle: '고급',
            stageDescription: '도전 과제를 해결하는 고급 단계입니다.',
          ),
        ),
      );
      return true;
    }
    if (normalized.contains('설정')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen(isActive: true)),
      );
      return true;
    }

    return false;
  }
}
