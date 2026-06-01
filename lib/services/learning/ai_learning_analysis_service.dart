import 'dart:io';

import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/services/ai/ai_service.dart';
import 'package:puzzle_dot/services/learning/learning_analysis_service.dart';

class AiLearningAnalysisService implements ILearningAnalysisService {
  final _ai = AiService();

  Future<void> initialize() => _ai.initialize();

  @override
  void dispose() => _ai.dispose();

  @override
  Future<LearningResult> analyzeImage({
    required String imagePath,
    required CurriculumItem targetItem,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final answerVectors = _parseAnswerVectors(targetItem.dotPattern);

    final result = await _ai.analyzeImageWithDebug(imageBytes, answerVectors);
    final parsed = AiResult.fromJson(result.json);

    if (parsed is MatchResult) {
      return LearningResult.correct();
    }

    if (parsed is MismatchResult) {
      return LearningResult.incorrect(
        parsed.toTtsMessage(),
        wrongCellIndexes: parsed.wrongIndices,
      );
    }

    if (parsed is ErrorResult) {
      return LearningResult.incomplete(parsed.toTtsMessage());
    }

    // ExtractedResult: dotPattern에 벡터가 없는 경우 (랜덤 출제 등)
    return LearningResult.incomplete('점자 형태를 확인할 수 없어요. 다시 시도해주세요.');
  }

  /// dotPattern 문자열에서 정답 벡터 목록 파싱
  ///
  /// 단일셀: '[0,0,0,1,0,0]'                          → [[0,0,0,1,0,0]]
  /// 멀티셀: '셀1=[1,0,0,0,0,0] / 셀2=[0,1,1,1,0,0]' → [[1,0,0,0,0,0],[0,1,1,1,0,0]]
  /// 벡터 없음 (랜덤 등):                              → null
  List<List<int>>? _parseAnswerVectors(String dotPattern) {
    final matches = RegExp(r'\[(\d(?:,\d){5})\]').allMatches(dotPattern);
    if (matches.isEmpty) return null;
    return matches
        .map((m) => m.group(1)!.split(',').map(int.parse).toList())
        .toList();
  }
}
