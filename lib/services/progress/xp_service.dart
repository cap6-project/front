import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_dot/core/constants/prefs_keys.dart';

/// XP 저장 서비스
///
/// 역할:
/// - 학습 단계 완료 시 XP 누적
/// - 누적 XP 조회
/// - 화면이 SharedPreferences 키를 직접 알지 않도록 분리
class XpService {
  XpService._();

  static const int xpPerItem = 150;

  static Future<int> addXp({int amount = xpPerItem}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(PrefsKeys.totalXp) ?? 0;
    final updated = current + amount;

    await prefs.setInt(PrefsKeys.totalXp, updated);
    return updated;
  }

  static Future<int> getTotalXp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PrefsKeys.totalXp) ?? 0;
  }
}