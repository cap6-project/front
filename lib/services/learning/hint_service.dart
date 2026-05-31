import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

/// 오답 힌트 생성 서비스
///
/// 역할:
/// - 커리큘럼 항목 기반 힌트 생성
/// - 틀린 셀 인덱스 기반 안내 문장 생성
/// - 미완료 상태 힌트 생성
/// - 추후 AI/OpenCV 분석 결과 벡터 기반 힌트 생성
class HintService {
  const HintService();

  /// 기본 오답 힌트
  ///
  /// 화면 표시용 원문 반환
  /// TTS 발음 치환은 화면에서 speak 직전에만 적용
  String incorrectHint(CurriculumItem item) {
    final reading = item.reading.trim();
    final character = item.character.trim();
    final label = reading.isNotEmpty ? reading : character;

    return '$label 점형을 다시 확인해주세요.';
  }

  /// 틀린 셀 인덱스 기반 오답 힌트
  ///
  /// AI 결과가 틀린 셀 인덱스를 포함할 때 사용
  String wrongCellHint({
    required CurriculumItem item,
    required List<int> wrongCellIndexes,
  }) {
    if (wrongCellIndexes.isEmpty) {
      return incorrectHint(item);
    }

    final cellText = cellIndexListText(wrongCellIndexes);
    return '$cellText을 다시 확인해주세요. ${incorrectHint(item)}';
  }

  /// 사용자 화면 표시용 셀 목록
  ///
  /// 내부 인덱스는 0부터 시작
  /// 화면에서는 1번 셀부터 표시
  String cellIndexListText(List<int> wrongCellIndexes) {
    if (wrongCellIndexes.isEmpty) {
      return '틀린 셀';
    }

    final labels = wrongCellIndexes.map((index) => '${index + 1}번 셀').toList();
    return labels.join(', ');
  }

  /// 촬영/분석 미완료 힌트
  String incompleteHint() {
    return TtsScriptProvider.incompleteHint();
  }

  /// AI/OpenCV 벡터 기반 힌트 연결 지점
  ///
  /// TODO: AI/OpenCV 팀의 벡터 포맷 확정 후 비교 로직 구현
  String hintFromDotVectors({
    required CurriculumItem item,
    required List<int> expectedDots,
    required List<int> actualDots,
  }) {
    if (expectedDots.isEmpty || actualDots.isEmpty) {
      return incompleteHint();
    }

    return incorrectHint(item);
  }
}
