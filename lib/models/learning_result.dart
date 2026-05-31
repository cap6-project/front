enum LearningResultType { correct, incorrect, incomplete }

/// 학습 분석 결과 모델
///
/// 역할:
/// - 정답/오답/미완료 결과 표현
/// - 힌트 TTS 문장 전달
/// - 오답 시 AI가 반환한 틀린 셀 인덱스 전달
/// - 실제 AI/OpenCV 결과 연결 시에도 동일 모델 사용
class LearningResult {
  final LearningResultType type;
  final String hint;
  final double? confidence;

  /// AI/OpenCV가 반환한 틀린 셀 인덱스
  ///
  /// 내부 값은 0부터 시작
  /// 화면 표시 시 사용자용 번호로 +1 처리
  final List<int> wrongCellIndexes;

  const LearningResult({
    required this.type,
    this.hint = '',
    this.confidence,
    this.wrongCellIndexes = const [],
  });

  bool get isCorrect => type == LearningResultType.correct;
  bool get isIncorrect => type == LearningResultType.incorrect;
  bool get isIncomplete => type == LearningResultType.incomplete;
  bool get hasWrongCellIndexes => wrongCellIndexes.isNotEmpty;

  factory LearningResult.correct() {
    return const LearningResult(
      type: LearningResultType.correct,
      hint: '정답입니다.',
      confidence: 1.0,
    );
  }

  factory LearningResult.incorrect(
    String hint, {
    List<int> wrongCellIndexes = const [],
    double? confidence,
  }) {
    return LearningResult(
      type: LearningResultType.incorrect,
      hint: hint,
      confidence: confidence,
      wrongCellIndexes: wrongCellIndexes,
    );
  }

  factory LearningResult.incomplete(String hint) {
    return LearningResult(type: LearningResultType.incomplete, hint: hint);
  }

  /// AI/OpenCV Map 응답 변환 지점
  ///
  /// 팀별 응답 키가 조금 달라도 화면 모델은 동일하게 유지
  /// 실제 응답 형식 확정 시 이 함수의 키 매핑만 정리
  factory LearningResult.fromAnalysisMap(Map<String, dynamic> value) {
    final rawType = '${value['type'] ?? value['result'] ?? value['status']}';
    final normalizedType = rawType.toLowerCase();
    final hint = '${value['hint'] ?? value['message'] ?? ''}'.trim();
    final confidence = _tryParseDouble(value['confidence']);
    final wrongCellIndexes = _parseWrongCellIndexes(value);

    if (normalizedType.contains('correct') ||
        normalizedType == 'true' ||
        value['isCorrect'] == true) {
      return LearningResult.correct();
    }

    if (normalizedType.contains('incomplete') ||
        normalizedType.contains('pending')) {
      return LearningResult.incomplete(
        hint.isEmpty ? '점자가 화면 중앙에 오도록 다시 촬영해주세요.' : hint,
      );
    }

    return LearningResult.incorrect(
      hint.isEmpty ? '점자 모양을 다시 확인해주세요.' : hint,
      confidence: confidence,
      wrongCellIndexes: wrongCellIndexes,
    );
  }

  static double? _tryParseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<int> _parseWrongCellIndexes(Map<String, dynamic> value) {
    final raw =
        value['wrongCellIndexes'] ??
        value['wrongCellIndices'] ??
        value['wrong_cells'] ??
        value['wrongCells'] ??
        value['incorrectCellIndexes'];

    if (raw is Iterable) {
      return raw.map((item) => int.tryParse('$item')).whereType<int>().toList();
    }

    if (raw is num) {
      return [raw.toInt()];
    }

    if (raw is String) {
      return raw
          .split(RegExp(r'[, ]+'))
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList();
    }

    return const [];
  }
}
