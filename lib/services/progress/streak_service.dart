import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_dot/core/constants/prefs_keys.dart';

/// 연속 학습일 계산 서비스
///
/// 역할:
/// - 하루 1개 이상 학습 완료 시 해당 날짜 학습 인정
/// - 어제와 오늘이 이어지면 streak 증가
/// - 하루 이상 비면 1일로 초기화
class StreakService {
  StreakService._();

  static Future<int> recordActivityAndGetStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final today = _todayString();
    final lastDate = prefs.getString(PrefsKeys.streakLastDate);
    var streak = prefs.getInt(PrefsKeys.streakCount) ?? 0;

    if (lastDate == null) {
      streak = 1;
    } else if (lastDate == today) {
      return streak;
    } else {
      final last = DateTime.parse(lastDate);
      final current = DateTime.parse(today);
      final diff = current.difference(last).inDays;

      streak = diff == 1 ? streak + 1 : 1;
    }

    await prefs.setString(PrefsKeys.streakLastDate, today);
    await prefs.setInt(PrefsKeys.streakCount, streak);

    return streak;
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final lastDate = prefs.getString(PrefsKeys.streakLastDate);
    if (lastDate == null) return 0;

    final today = DateTime.parse(_todayString());
    final last = DateTime.parse(lastDate);
    final diff = today.difference(last).inDays;

    if (diff > 1) return 0;

    return prefs.getInt(PrefsKeys.streakCount) ?? 0;
  }

  static String _todayString() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}