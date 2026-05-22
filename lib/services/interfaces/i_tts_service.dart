/// TTS 실행 기능 최소 인터페이스
///
/// 화면이 flutter_tts 구현체에 직접 의존하지 않도록 분리
/// mock TTS 또는 테스트용 TTS로 교체하기 쉬운 구조
abstract class ITtsService {
  Future<void> speak(
    String text, {
    bool interrupt = true,
  });

  Future<void> stop();
}