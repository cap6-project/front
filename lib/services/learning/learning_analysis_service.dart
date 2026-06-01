import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';

/// 학습 이미지 분석 서비스 인터페이스
///
/// 역할:
/// - 화면이 mock/실제 분석 구현체에 직접 의존하지 않게 분리
/// - AI/OpenCV 분석 서비스 교체 지점 제공
abstract class ILearningAnalysisService {
  Future<LearningResult> analyzeImage({
    required String imagePath,
    required CurriculumItem targetItem,
  });

  void dispose() {}
}