enum LearningResultType {
  correct,
  incorrect,
  incomplete,
}

/// 학습 분석 결과 모델
///
/// 역할:
/// - 정답/오답/미완료 결과 표현
/// - 힌트 TTS 문장 전달
/// - 실제 AI/OpenCV 결과 연결 시에도 동일 모델 사용
class LearningResult {
  final LearningResultType type;
  final String hint;
  final double? confidence;

  const LearningResult({
    required this.type,
    this.hint = '',
    this.confidence,
  });

  bool get isCorrect => type == LearningResultType.correct;
  bool get isIncorrect => type == LearningResultType.incorrect;
  bool get isIncomplete => type == LearningResultType.incomplete;

  factory LearningResult.correct() {
    return const LearningResult(
      type: LearningResultType.correct,
      hint: '정답입니다.',
      confidence: 1.0,
    );
  }

  factory LearningResult.incorrect(String hint) {
    return LearningResult(
      type: LearningResultType.incorrect,
      hint: hint,
    );
  }

  factory LearningResult.incomplete(String hint) {
    return LearningResult(
      type: LearningResultType.incomplete,
      hint: hint,
    );
  }
}