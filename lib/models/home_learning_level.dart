enum HomeLevelGroup {
  intro,
  beginner,
  intermediate,
  advanced,
}

/// 홈 화면 레벨 표시 모델
///
/// 역할:
/// - 홈 카드에 필요한 레벨 정보 보관
/// - 커리큘럼 원본 데이터와 홈 UI 표시 데이터 분리
class HomeLearningLevel {
  final String id;
  final String title;
  final String subtitle;
  final HomeLevelGroup group;

  const HomeLearningLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.group,
  });
}