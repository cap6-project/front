import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/services/learning/learning_analysis_service.dart';

/// 개발용 mock 분석 서비스
///
/// 역할:
/// - 실제 AI/OpenCV 연결 전 정답/오답/미완료 흐름 확인
/// - 배포용 분석 로직과 분리
/// - 실제 구현체로 교체 가능한 구조 유지
class MockLearningAnalysisService implements ILearningAnalysisService {
  @override
  Future<LearningResult> analyzeImage({
    required String imagePath,
    required CurriculumItem targetItem,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final seed = imagePath.hashCode.abs() % 3;

    if (seed == 0) {
      return LearningResult.correct();
    }

    if (seed == 1) {
      return LearningResult.incorrect(
        '${targetItem.character} 점형을 다시 확인해주세요.',
      );
    }

    return LearningResult.incomplete(
      '점자가 화면 중앙에 오도록 다시 촬영하거나 이미지를 선택해주세요.',
    );
  }
}