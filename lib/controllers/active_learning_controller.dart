import 'package:flutter/foundation.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/services/learning/learning_analysis_service.dart';
import 'package:puzzle_dot/services/learning/mock_learning_analysis_service.dart';
import 'package:puzzle_dot/services/progress_service.dart';

/// Active Learning 상태 컨트롤러
///
/// 역할:
/// - 이미지 분석 요청
/// - 정답 시 진도 저장
/// - 화면에 필요한 분석 상태만 노출
///
/// UI는 분석 서비스와 저장소 구현체를 직접 호출하지 않음
class ActiveLearningController extends ChangeNotifier {
  final CurriculumItem targetItem;
  final ILearningAnalysisService _analysisService;

  ActiveLearningController({
    required this.targetItem,
    ILearningAnalysisService? analysisService,
  }) : _analysisService = analysisService ?? MockLearningAnalysisService();

  bool _isAnalyzing = false;
  LearningResult? _lastResult;

  bool get isAnalyzing => _isAnalyzing;
  LearningResult? get lastResult => _lastResult;

  Future<LearningResult> analyzeImage(String imagePath) async {
    if (_isAnalyzing) {
      return LearningResult.incomplete('이미 분석 중입니다. 잠시 기다려주세요.');
    }

    _setAnalyzing(true);

    final result = await _analysisService.analyzeImage(
      imagePath: imagePath,
      targetItem: targetItem,
    );

    await _applyResult(result);

    _lastResult = result;
    _setAnalyzing(false);

    return result;
  }

  /// debug 전용 결과 주입
  ///
  /// 실제 AI/OpenCV 분석과 분리된 테스트 진입점
  Future<LearningResult> applyDebugResult(LearningResult result) async {
    await _applyResult(result);
    _lastResult = result;
    notifyListeners();
    return result;
  }

  Future<void> _applyResult(LearningResult result) async {
    if (result.isCorrect) {
      await ProgressService.markCompleted(targetItem.id);
    }
  }

  void _setAnalyzing(bool value) {
    if (_isAnalyzing == value) return;

    _isAnalyzing = value;
    notifyListeners();
  }
}