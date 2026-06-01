# 퍼즐닷 AI 모듈 — 프론트엔드 통합 가이드

> AI 모듈을 학습 화면/번역 화면에 통합하는 FE팀용 매뉴얼.
> 코드 복사해서 그대로 쓰면 됩니다.

---

## 0. 준비 — 모듈 파일 위치

이 디렉토리 구조가 프로젝트에 이미 있어야 합니다 (PM이 작업해둠):

```
lib/
├── main.dart                       ← 테스트용 (참고만, FE는 자기 화면에서 호출)
├── services/
│   ├── ai_service.dart             ← ★ FE가 import 할 메인 파일
│   ├── cnn_service.dart            ← 내부용 (직접 안 씀)
│   └── vision_service.dart         ← 내부용 (직접 안 씀)
├── constants/
│   └── answer_vectors.dart         ← 정답 패턴 (자모, 음절, 음원 등)
├── utils/
│   └── signal_utils.dart           ← 내부용
└── assets/models/
    └── cell_detector.tflite        ← AI 모델 (이미 등록됨)
```

---

## 1. 초기화 — 앱 시작 시 한 번만

`AiService`는 **싱글톤처럼 한 번 만들고 재사용**합니다.
CNN 모델 로드에 1초 정도 걸리니까 **앱 시작 시점**에 미리 해두세요.

### 1-1. import

```dart
import 'package:puzzledot/services/ai_service.dart';
```

### 1-2. 인스턴스 생성 + 초기화

```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final _ai = AiService();   // ★ 한 번만 생성
  bool _aiReady = false;

  @override
  void initState() {
    super.initState();
    _initAi();
  }

  Future<void> _initAi() async {
    await _ai.initialize();   // CNN 모델 로드 (1초 정도 걸림)
    setState(() => _aiReady = true);
  }

  @override
  void dispose() {
    _ai.dispose();   // ★ 화면 종료 시 반드시 호출
    super.dispose();
  }
}
```

**주의**:
- `initialize()`는 비동기. 안 끝났는데 `analyzeImage()` 호출하면 자동으로 대기하긴 하지만 첫 호출이 느려짐.
- `dispose()` 안 부르면 메모리 누수.

### 1-3. 앱 전체에서 공유하려면

여러 화면에서 쓴다면 `Provider`나 `GetIt`으로 싱글톤 등록 추천:

```dart
// main.dart 같은 진입점에서
final aiService = AiService();
await aiService.initialize();

runApp(
  Provider.value(value: aiService, child: MyApp()),
);

// 어떤 화면에서든
final ai = context.read<AiService>();
```

---

## 2. 사용 방법 — 두 가지 케이스

### 케이스 A: 번역 모드 (점자 → 한글)

사용자가 점자 사진 찍으면 한글로 보여주는 화면.

```dart
import 'dart:typed_data';
import 'package:puzzledot/services/ai_service.dart';
import 'package:puzzledot/constants/answer_vectors.dart';

Future<void> _analyzeForTranslation(Uint8List imageBytes) async {
  // 정답 벡터는 null (번역 모드는 정답 검증 없이 추출만)
  final result = await _ai.analyzeImageWithDebug(imageBytes, null);
  final parsed = AiResult.fromJson(result.json);

  if (parsed is ExtractedResult) {
    // 6비트 벡터 목록 → 한글로 매칭
    final vectors = parsed.vectors;
    final koreanWords = <String>[];

    for (final vec in vectors) {
      final id = _matchVectorToId(vec);          // 아래 함수 정의
      koreanWords.add(_idToKorean(id ?? '?'));   // 아래 함수 정의
    }

    print('인식: ${koreanWords.join(' ')}');
    // 예: "ㄴ ㅊ ㅋ ㄱ ㅎ ㄹ ㅌ ㅁ ㅍ ㅅ ㅈ"

    // 디버그 이미지가 필요하면
    if (result.debugImage != null) {
      // 화면에 표시: Image.memory(result.debugImage!)
    }
  } else if (parsed is ErrorResult) {
    print('오류: ${parsed.toTtsMessage()}');
  }
}

/// 6비트 벡터 → ID 매칭 (우선순위: CON > VOW > SYL > FIN > WRD > NUM > ENT)
String? _matchVectorToId(List<int> vec) {
  const priorityPrefixes = ['CON', 'VOW', 'SYL', 'FIN', 'WRD', 'NUM', 'ENT'];

  for (final prefix in priorityPrefixes) {
    for (final entry in AnswerVectors.all.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final answer = entry.value;
      if (answer is List && answer.isNotEmpty && answer.first is int) {
        final answerList = List<int>.from(answer);
        if (answerList.length != 6) continue;
        bool match = true;
        for (int i = 0; i < 6; i++) {
          if (answerList[i] != vec[i]) { match = false; break; }
        }
        if (match) return entry.key;
      }
    }
  }
  return null;
}

/// ID → 한글 표시 문자열
String _idToKorean(String id) {
  const map = {
    'CON_001': 'ㄱ', 'CON_002': 'ㄴ', 'CON_003': 'ㄷ', 'CON_004': 'ㄹ',
    'CON_005': 'ㅁ', 'CON_006': 'ㅂ', 'CON_007': 'ㅅ', 'CON_008': 'ㅇ',
    'CON_009': 'ㅈ', 'CON_010': 'ㅊ', 'CON_011': 'ㅋ', 'CON_012': 'ㅌ',
    'CON_013': 'ㅍ', 'CON_014': 'ㅎ',
    // ... (main.dart의 _idToKorean 함수에 전체 매핑 있음, 복사해서 사용)
  };
  return map[id] ?? id;
}
```

### 케이스 B: 학습 모드 (정답과 비교)

사용자에게 "ㄱ을 만들어보세요"라고 한 다음, 사진 받아서 맞나 검증.

```dart
Future<void> _analyzeForLearning(Uint8List imageBytes, String targetId) async {
  // 정답 벡터 가져오기
  final answerVector = AnswerVectors.get(targetId);  // 예: 'CON_001' → [0,0,0,1,0,0]

  final result = await _ai.analyzeImageWithDebug(imageBytes, answerVector);
  final parsed = AiResult.fromJson(result.json);

  if (parsed is MatchResult) {
    // 🎉 정답!
    await _tts.speak('정답입니다');
  } else if (parsed is MismatchResult) {
    // 어디가 틀렸는지 자세히
    final ttsMsg = parsed.toTtsMessage();
    // 예: "1번째 글자에서 4번 점이 빠졌어요"
    await _tts.speak(ttsMsg);

    // 셀별 상세 정보가 필요하면
    for (int i = 0; i < parsed.cells.length; i++) {
      final cell = parsed.cells[i];
      print('${i+1}번 셀:');
      print('  검출: ${cell.detected}');
      print('  정답: ${cell.correct}');
      print('  빠진 점: ${cell.missing}');     // 예: [4] (점4가 빠짐)
      print('  잘못된 점: ${cell.extra}');     // 예: [3] (점3을 잘못 누름)
      print('  정답인가: ${cell.isCorrect}');
    }
  } else if (parsed is ErrorResult) {
    await _tts.speak(parsed.toTtsMessage());
  }
}
```

### 케이스 B-1: 단어/문장 (여러 셀)

`AnswerVectors.get('WRD_001')` 같은 여러 셀짜리 정답도 그대로 동작:

```dart
// 약어 "그래서" = [[1,0,0,0,0,0], [0,1,1,1,0,0]]
final answer = AnswerVectors.get('WRD_001');
final result = await _ai.analyzeImageWithDebug(imageBytes, answer);
// 처리 동일
```

---

## 3. 메인 API 정리

### `AiService.initialize()`
- 한 번만 호출. CNN 모델 로드.
- 반환: `Future<void>`

### `AiService.analyzeImageWithDebug(imageBytes, [answerVector])`
- **권장 진입점.** 분석 결과 + 디버그 이미지를 함께 반환.
- 파라미터:
  - `imageBytes` (`Uint8List`): 사진 바이트
  - `answerVector` (선택): 정답 벡터 (단일 셀, 여러 셀, null 모두 OK)
- 반환: `Future<AnalysisResult>` (안에 `.json`과 `.debugImage`)

### `AiService.analyzeImage(imageBytes, [answerVector])`
- 디버그 이미지가 필요 없으면 이걸 호출. 약간 빠름.
- 반환: `Future<Map<String, dynamic>>` (JSON 결과만)

### `AiService.dispose()`
- 화면 종료 시 호출. CNN 모델 메모리 해제.

---

## 4. 결과 타입 (AiResult)

`AiResult.fromJson()`으로 만들면 다음 4가지 중 하나:

### `ExtractedResult` (정답 벡터 없이 호출)
```dart
parsed.vectors  // List<List<int>> - 셀마다 6비트 벡터
```
번역 모드에서 사용.

### `MatchResult` (정답이랑 일치)
```dart
parsed.toTtsMessage()  // "정답입니다!"
```

### `MismatchResult` (정답이랑 불일치)
```dart
parsed.cells           // List<CellResult>
parsed.wrongIndices    // List<int> - 틀린 셀 인덱스들
parsed.toTtsMessage()  // 자동 생성된 안내 (셀별 빠진/잘못된 점)
```

`CellResult` 한 개:
```dart
cell.detected   // List<int> - 사진에서 검출된 벡터
cell.correct    // List<int> - 정답 벡터
cell.missing    // List<int> - 빠진 점 번호 (1~6)
cell.extra      // List<int> - 잘못 들어간 점 번호
cell.isCorrect  // bool
cell.toTtsMessage(cellIndex: i)  // "1번째 글자에서 4번 점이 빠졌어요"
```

### `ErrorResult` (인식 실패)
```dart
parsed.code            // 에러 코드
parsed.toTtsMessage()  // 사용자에게 들려줄 안내
```

에러 코드:
- `NO_CELL_DETECTED`: 점자가 안 보임 → "사진을 다시 찍어주세요"
- `CELL_COUNT_MISMATCH`: 셀 개수가 정답과 다름 → "셀 개수가 맞지 않아요"
- `IMAGE_DECODE_FAIL`: 이미지 로드 실패
- 기타: 일반 인식 실패

---

## 5. TTS 통합 권장 패턴

분석은 250~300ms 정도 걸리므로 사용자에게 진행 중임을 알리는 게 좋아요.

```dart
import 'package:flutter_tts/flutter_tts.dart';

final _tts = FlutterTts();

@override
void initState() {
  super.initState();
  _tts.setLanguage('ko-KR');
  _tts.setSpeechRate(0.5);
}

Future<void> _analyze(Uint8List imageBytes) async {
  // 1) 분석 시작 안내 (시각장애인용)
  await _tts.speak('분석 중입니다');

  // 2) 실제 분석
  final result = await _ai.analyzeImageWithDebug(imageBytes, answerVector);
  final parsed = AiResult.fromJson(result.json);

  // 3) "분석 중입니다" 아직 안 끝났으면 stop으로 중단
  await _tts.stop();

  // 4) 결과 안내
  String ttsMsg = '...'; // 결과에 따라 결정
  await _tts.speak(ttsMsg);
}
```

---

## 6. 정답 벡터 사용법 (answer_vectors.dart)

### 6-1. ID로 정답 조회

```dart
import 'package:puzzledot/constants/answer_vectors.dart';

// 단일 셀
final ga = AnswerVectors.get('SYL_001');  // [1,0,0,1,0,1] (가)

// 여러 셀
final word = AnswerVectors.get('WRD_001');  // [[1,0,0,0,0,0], [0,1,1,1,0,0]] (그래서)
```

### 6-2. 카테고리

| 접두사 | 의미 | 개수 | 예 |
|---|---|---|---|
| ENT_ | 입문 (점1~6) | 6 | ENT_001 = 점1 |
| CON_ | 자음 | 19 | CON_001 = ㄱ |
| VOW_ | 모음 | 21 | VOW_001 = ㅏ |
| SYL_ | 음절 약자 | 11 | SYL_001 = 가 |
| WRD_ | 약어 | 7 | WRD_001 = 그래서 |
| FIN_ | 종성 | 8 | FIN_001 = 억 |
| NUM_ | 숫자 | 6 | NUM_001 = 수표 |

### 6-3. 학습 콘텐츠가 정답 ID를 지정해서 사용

기획서/콘텐츠 데이터에 ID를 박아두고 그걸로 검증:

```dart
// 콘텐츠 예시
final lesson = {
  'title': 'ㄱ 따라 만들기',
  'targetId': 'CON_001',
  'guidance': '오른쪽 위 점 하나만 누르면 ㄱ이에요',
};

// 검증
final answer = AnswerVectors.get(lesson['targetId']);
final result = await _ai.analyzeImageWithDebug(imageBytes, answer);
```

---

## 7. 디버그 이미지 활용 (선택사항)

분석 후 사진 위에 셀 박스와 6점 위치를 그린 이미지를 받을 수 있어요:

```dart
final result = await _ai.analyzeImageWithDebug(imageBytes, null);

if (result.debugImage != null) {
  // Image.memory로 표시
  Image.memory(result.debugImage!);
}
```

- 🟢 녹색 박스: AI가 검출한 셀 위치 (정규화 후)
- 🔴 빨간 원: 점이 측정된 위치

**개발 중 디버깅**, **사용자에게 "AI가 어떻게 보고 있는지" 보여주기** 등에 유용.
프로덕션에서는 평소엔 안 보이게 하고 "AI 보기" 버튼 같은 거 누르면 보이게 추천.

---

## 8. 자주 묻는 질문

### Q. 사진 해상도 권장 사항?
이미지가 5712×4284까지 처리됨. 그 이상이면 자동으로 1280으로 축소.
**일반 스마트폰 카메라로 찍은 사진 그대로 넣으면 됨.**

### Q. 사진 촬영 조건?
- 흰 종이 위에 점자 교구 올리고 촬영 권장
- 균일한 조명 (그림자 최소화)
- 카메라가 점자 교구와 수직 (살짝 기울어도 RANSAC이 보정)
- 점자 핀 끝이 검정 매직으로 칠해져 있어야 함

### Q. 최대 몇 셀까지 인식?
현재 11셀까지 100% 정확도 확인. 15셀 (전화번호) 목표로 진행 중.
**셀이 적을수록 안정적** (5셀, 9셀 완벽).

### Q. 같은 패턴이 여러 ID에 등록된 경우?
예: `[0,0,0,1,0,0]` = 점4(ENT_004) = ㄱ(CON_001)
**자동으로 우선순위 적용** (CON > VOW > SYL > FIN > WRD > NUM > ENT).
→ 번역 시 ㄱ으로 매칭 (자모가 의미 있으므로).

학습 모드에선 ID로 직접 검증하니까 충돌 없음.

### Q. 빈 셀(점 0개)도 인식 가능?
가능. 알고리즘이 자동으로 빈 셀을 판단해서 `[0,0,0,0,0,0]` 반환.

### Q. 분석 시간이 너무 오래 걸려요
대부분 CNN 추론 시간 (200ms). 에뮬레이터는 더 느림.
- 실기기에서 테스트: 100~200ms 예상
- 첫 분석은 모델 캐싱 때문에 약간 더 느림 (이후엔 빠름)

### Q. 결과가 부정확해요
1. 디버그 이미지로 셀 박스가 맞게 그려지는지 확인
2. 점자 핀에 검정 매직이 진하게 칠해졌는지 확인
3. 조명이 균일한지, 그림자가 셀에 안 떨어지는지 확인
4. 카메라가 점자와 수직인지 확인

---

## 9. 통합 체크리스트

학습/번역 화면 만들 때 확인:

- [ ] `AiService` import 했나
- [ ] 화면 진입 시 `initialize()` 호출했나
- [ ] 화면 종료 시 `dispose()` 호출했나
- [ ] 사용자에게 사진 촬영 가이드 안내했나 (흰 종이, 수직 촬영 등)
- [ ] 분석 중 로딩 표시 + TTS 안내했나
- [ ] `MatchResult`, `MismatchResult`, `ErrorResult` 케이스 모두 처리했나
- [ ] 시각장애인 사용자를 위한 TTS 처리했나
- [ ] 분석 시간 너무 길어지면 타임아웃 처리했나 (선택)
