/// 앱 전체 TTS 설정값을 한 곳에서 관리
///
/// 화면마다 speechRate, pitch 등을 직접 설정 시 속도 차이와 중복 실행 문제 발생 쉬움
/// 모든 TTS 구현체는 이 설정을 기준으로 초기화
class TtsConfig {
  TtsConfig._();

  static const String language = 'ko-KR';

  /// 학습 안내용 속도
  ///
  /// 기존보다 천천히 읽어 접근성 기준에 맞춤
  static const double speechRate = 0.48;

  static const double volume = 1.0;
  static const double pitch = 1.0;

  /// 긴 학습 안내 문장 중간 끊김 방지
  ///
  /// iOS/Android TTS 완료 콜백 누락 대비
  static const Duration fallbackCompletionWait = Duration(seconds: 12);
}