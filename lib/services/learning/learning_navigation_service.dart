import 'package:puzzle_dot/models/curriculum_item.dart';

/// 학습 단계 이동 계산 서비스
///
/// 역할:
/// - 현재 학습 항목 조회
/// - 다음 학습 항목 조회
/// - 다음 단계 존재 여부 판단
///
/// 화면은 index 계산 규칙을 직접 알지 않음
/// 다음 단계 정책 변경 시 이 파일만 수정
class LearningNavigationService {
  LearningNavigationService._();

  static bool hasNext({
    required List<CurriculumItem>? items,
    required int? currentIndex,
  }) {
    if (!_hasValidPosition(items: items, currentIndex: currentIndex)) {
      return false;
    }

    return currentIndex! + 1 < items!.length;
  }

  static CurriculumItem? getCurrentItem({
    required List<CurriculumItem>? items,
    required int? currentIndex,
  }) {
    if (!_hasValidPosition(items: items, currentIndex: currentIndex)) {
      return null;
    }

    return items![currentIndex!];
  }

  static CurriculumItem? getNextItem({
    required List<CurriculumItem>? items,
    required int? currentIndex,
  }) {
    final nextIndex = getNextIndex(
      items: items,
      currentIndex: currentIndex,
    );

    if (nextIndex == null) return null;

    return items![nextIndex];
  }

  static int? getNextIndex({
    required List<CurriculumItem>? items,
    required int? currentIndex,
  }) {
    if (!hasNext(items: items, currentIndex: currentIndex)) {
      return null;
    }

    return currentIndex! + 1;
  }

  static bool _hasValidPosition({
    required List<CurriculumItem>? items,
    required int? currentIndex,
  }) {
    if (items == null || items.isEmpty) return false;
    if (currentIndex == null) return false;
    if (currentIndex < 0) return false;
    if (currentIndex >= items.length) return false;

    return true;
  }
}