import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/services/hint_service.dart';
import 'package:puzzle_dot/services/learning/learning_analysis_service.dart';

/// 개발용 mock 분석 서비스
///
/// 역할:
/// - 실제 AI/OpenCV 연결 전 정답/오답/미완료 흐름 확인
/// - 결과 타입 결정
/// - 힌트 문장 생성은 HintService에 위임
///
/// 실제 분석 구현체로 교체 가능한 구조 유지
class MockLearningAnalysisService implements ILearningAnalysisService {
  final HintService _hintService;

  const MockLearningAnalysisService({
    HintService hintService = const HintService(),
  }) : _hintService = hintService;

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
        _hintService.incorrectHint(targetItem),
      );
    }

    return LearningResult.incomplete(
      _hintService.incompleteHint(),
    );
  }
}