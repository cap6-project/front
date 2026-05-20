import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

/// 오답 힌트 생성 서비스
///
/// 역할:
/// - 커리큘럼 항목 기반 힌트 생성
/// - 미완료 상태 힌트 생성
/// - 추후 AI/OpenCV 분석 결과 벡터 기반 힌트 생성
///
/// TTS 자연화는 TtsScriptProvider가 담당
class HintService {
  const HintService();

  /// 기본 오답 힌트
  ///
  /// 현재는 목표 점형 재확인 중심
  /// 추후 expected/actual 벡터 비교 결과로 상세 힌트 생성
  String incorrectHint(CurriculumItem item) {
    return TtsScriptProvider.incorrectHint(item);
  }

  /// 촬영/분석 미완료 힌트
  ///
  /// 점자판 위치나 이미지 상태가 불충분할 때 사용
  String incompleteHint() {
    return TtsScriptProvider.incompleteHint();
  }

  /// AI/OpenCV 벡터 기반 힌트 연결 지점
  ///
  /// expectedDots: 정답 점 위치
  /// actualDots: 촬영 후 추출된 점 위치
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