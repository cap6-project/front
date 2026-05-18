class PrefsKeys {
  PrefsKeys._();
  static const String donePrefix    = 'done_';
  static const String streakDate    = 'streak_last_date';
  static const String streakCount   = 'streak_count';
  static const String totalXp       = 'total_xp';
  static String doneKey(String id)  => '$donePrefix$id';
}