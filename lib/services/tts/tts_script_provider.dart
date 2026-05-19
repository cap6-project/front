import 'package:puzzle_dot/models/curriculum_item.dart';

/// TTS 안내 문장 관리
///
/// 역할:
/// - 화면별 음성 안내 문장 제공
/// - 화면 표시 문구와 음성 문구 분리
/// - 점형 표현을 자연스러운 한국어로 변환
class TtsScriptProvider {
  TtsScriptProvider._();

  static const String onboardingWelcome =
      '퍼즐닷 점자 학습 앱에 오신 것을 환영합니다. '
      '이 앱에서는 점자 위치를 익히고, 자음과 모음, 받침, 숫자를 단계별로 학습할 수 있습니다. '
      '학습을 시작하려면 화면 아래의 학습 시작하기 버튼을 눌러주세요.';

  static const String cameraGuide =
      '보호자분께서 스마트폰 카메라가 점자판 바로 위를 향하도록 거치해주세요. '
      '점자판 전체가 화면에 들어와야 합니다. '
      '준비되면 확인 버튼을 눌러주세요.';

  static const String cameraPermissionRequired =
      '카메라 권한이 필요합니다. 설정에서 카메라 권한을 허용해주세요.';

  static const String cameraPermissionRetry =
      '카메라 권한을 다시 확인합니다. 권한을 허용한 뒤 다시 확인해주세요.';

  static const String cameraUnavailable =
      '이 기기에서는 카메라를 사용할 수 없습니다. 실제 기기에서 다시 확인해주세요.';

  static const String cameraReady =
      '점자판을 화면 중앙에 맞춘 뒤 촬영 버튼을 눌러주세요.';

  static const String capturing = '촬영 중입니다.';
  static const String analyzing = '분석 중입니다. 잠시 기다려주세요.';
  static const String captureFailed = '촬영에 실패했습니다. 다시 시도해주세요.';

  static String curriculumSelection(String levelTitle) {
    return '$levelTitle 학습 단계입니다. 학습할 항목을 선택하세요.';
  }

  static String learningGuide(CurriculumItem item) {
    if (item.ttsGuide.isNotEmpty) {
      return normalizeForSpeech(item.ttsGuide);
    }

    return '이번 학습은 ${spokenItemName(item.character)}, '
        '${normalizeForSpeech(item.description)}입니다. '
        '점자판을 완성한 뒤 촬영 버튼을 눌러주세요.';
  }

  static String progressSummary({
    required int completedCount,
    required int totalCount,
  }) {
    return '전체 $totalCount개 중 $completedCount개 완료했습니다.';
  }

  static String completion({
    required String itemName,
    required int xpEarned,
  }) {
    final spokenName = spokenItemName(itemName);
    final itemMessage =
        spokenName.isEmpty ? '학습을 완료했습니다.' : '$spokenName 학습을 완료했습니다.';

    final xpMessage = xpEarned > 0
        ? '경험치 $xpEarned점을 획득했습니다.'
        : '이미 완료한 학습이라 추가 경험치는 없습니다.';

    return '정답입니다! $itemMessage $xpMessage';
  }

  static String incorrectHint(CurriculumItem item) {
    return '${spokenItemName(item.character)} 점형을 다시 확인해주세요.';
  }

  static String incompleteHint() {
    return '점자가 화면 중앙에 오도록 다시 촬영하거나 이미지를 선택해주세요.';
  }

  static String spokenItemName(String value) {
    return normalizeForSpeech(value.trim());
  }

  static String normalizeForSpeech(String value) {
    var result = value;

    final replacements = <String, String>{
      '1번점': '첫번째',
      '2번점': '두번째',
      '3번점': '세번째',
      '4번점': '네번째',
      '5번점': '다섯번째',
      '6번점': '여섯번째',
    };

    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    return result;
  }
}