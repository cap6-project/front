// ai_service.dart — Hybrid 구조 + 디버그 시각화 통합 API
// =====================================================================
// ★ 변경점:
//   analyzeImageWithDebug() 추가 - 검출/디버그/분석을 한 번에 처리해
//   셀 검출이 2번 돌던 문제 해결 (속도 ↑)
// =====================================================================

import 'dart:typed_data';
import 'cnn_service.dart';
import 'vision_service.dart';

/// analyzeImageWithDebug() 결과 (분석 JSON + 디버그 이미지)
class AnalysisResult {
  final Map<String, dynamic> json;
  final Uint8List? debugImage;
  const AnalysisResult({required this.json, this.debugImage});
}

class AiService {
  final _cnn = CnnService();
  final _vision = VisionService();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _cnn.loadModels();
    _initialized = true;
    print('[AI] 초기화 완료');
  }

  /// ★ 권장 진입점 - 검출 1회로 분석 + 디버그 이미지 한 번에 처리
  Future<AnalysisResult> analyzeImageWithDebug(
    Uint8List imageBytes, [
    dynamic answerVector,
  ]) async {
    if (!_initialized) await initialize();

    final answerVectors = _normalizeAnswerVector(answerVector);

    // 셀 검출 (한 번만)
    final cellBoxes = await _cnn.detectCells(imageBytes);
    print('[AI] 셀 박스: ${cellBoxes.length}개');

    // 디버그 시각화
    final debugImage = _vision.debugVisualize(imageBytes, cellBoxes);

    // 분석
    final result = _vision.analyze(
      cellBoxes: cellBoxes,
      imageBytes: imageBytes,
      answerVectors: answerVectors,
    );

    return AnalysisResult(json: result.toJson(), debugImage: debugImage);
  }

  /// 기존 진입점 (호환용) - 디버그 이미지 필요 없으면 이걸 호출
  Future<Map<String, dynamic>> analyzeImage(
    Uint8List imageBytes, [
    dynamic answerVector,
  ]) async {
    if (!_initialized) await initialize();
    final answerVectors = _normalizeAnswerVector(answerVector);

    final cellBoxes = await _cnn.detectCells(imageBytes);
    print('[AI] 셀 박스: ${cellBoxes.length}개');

    final result = _vision.analyze(
      cellBoxes: cellBoxes,
      imageBytes: imageBytes,
      answerVectors: answerVectors,
    );

    return result.toJson();
  }

  List<List<int>>? _normalizeAnswerVector(dynamic answerVector) {
    if (answerVector == null) return null;
    if (answerVector is List<int>) return [answerVector];
    if (answerVector is List<List<int>>) return answerVector;
    if (answerVector is List) {
      if (answerVector.isNotEmpty && answerVector.first is int) {
        return [List<int>.from(answerVector)];
      } else {
        return answerVector.map<List<int>>((v) => List<int>.from(v as List)).toList();
      }
    }
    return null;
  }

  /// 셀 박스만 (디버그 외에 거의 안 씀)
  Future<List<List<double>>> getCellBoxes(Uint8List imageBytes) async {
    if (!_initialized) await initialize();
    return _cnn.detectCells(imageBytes);
  }

  VisionService get visionService => _vision;

  Future<String?> testHelloWorld() async {
    if (!_initialized) await initialize();
    return 'AI 작동 중';
  }

  void dispose() {
    _cnn.dispose();
  }
}

// =====================================================================
// AiResult 계층 (FE팀이 사용)
// =====================================================================

abstract class AiResult {
  const AiResult();

  factory AiResult.fromJson(Map<String, dynamic> json) {
    switch (json['result']) {
      case 'match':
        return MatchResult.fromJson(json);
      case 'mismatch':
        return MismatchResult.fromJson(json);
      case 'error':
        return ErrorResult(code: json['code'] as String? ?? 'UNKNOWN');
      case 'extracted':
        final vectors = (json['vectors'] as List)
            .map((v) => (v as List).cast<int>())
            .toList();
        return ExtractedResult(vectors: vectors);
      default:
        return const ErrorResult(code: 'UNKNOWN_RESULT_TYPE');
    }
  }
}

class MatchResult extends AiResult {
  final List<List<int>>? vectors;
  const MatchResult({this.vectors});

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final vectors = json['vectors'] != null
        ? (json['vectors'] as List).map((v) => (v as List).cast<int>()).toList()
        : null;
    return MatchResult(vectors: vectors);
  }

  String toTtsMessage() => '정답입니다!';
}

class CellResult {
  final List<int> detected;
  final List<int> correct;
  final List<int> missing;
  final List<int> extra;
  final bool isCorrect;

  const CellResult({
    required this.detected,
    required this.correct,
    required this.missing,
    required this.extra,
    required this.isCorrect,
  });

  factory CellResult.fromJson(Map<String, dynamic> json) => CellResult(
        detected: (json['detected'] as List).cast<int>(),
        correct: (json['correct'] as List).cast<int>(),
        missing: (json['missing'] as List).cast<int>(),
        extra: (json['extra'] as List).cast<int>(),
        isCorrect: json['is_correct'] as bool,
      );

  String toTtsMessage({int? cellIndex}) {
    if (isCorrect) return '정답';
    final prefix = cellIndex != null ? '${cellIndex + 1}번째 글자에서 ' : '';
    final parts = <String>[];
    if (missing.isNotEmpty) {
      parts.add('${missing.join(", ")}번 점이 빠졌어요');
    }
    if (extra.isNotEmpty) {
      parts.add('${extra.join(", ")}번 점은 잘못 들어갔어요');
    }
    return prefix + parts.join(', ');
  }
}

class MismatchResult extends AiResult {
  final List<CellResult> cells;
  const MismatchResult({required this.cells});

  factory MismatchResult.fromJson(Map<String, dynamic> json) {
    final cells = (json['cells'] as List)
        .map((c) => CellResult.fromJson(c as Map<String, dynamic>))
        .toList();
    return MismatchResult(cells: cells);
  }

  List<int> get wrongIndices {
    final result = <int>[];
    for (int i = 0; i < cells.length; i++) {
      if (!cells[i].isCorrect) result.add(i);
    }
    return result;
  }

  String toTtsMessage() {
    final wrong = <int>[];
    for (int i = 0; i < cells.length; i++) {
      if (!cells[i].isCorrect) wrong.add(i);
    }
    if (wrong.isEmpty) return '정답입니다.';
    if (wrong.length == 1) {
      final i = wrong.first;
      return cells[i].toTtsMessage(cellIndex: i);
    }
    final messages = wrong.map((i) => cells[i].toTtsMessage(cellIndex: i)).toList();
    return messages.join('. ') + '.';
  }
}

class ErrorResult extends AiResult {
  final String code;
  const ErrorResult({required this.code});

  String toTtsMessage() {
    switch (code) {
      case 'NO_CELL_DETECTED':
        return '점자 셀이 보이지 않아요. 사진을 다시 찍어주세요.';
      case 'NO_DETECTION':
        return '점자가 보이지 않아요.';
      case 'CELL_COUNT_MISMATCH':
        return '셀 개수가 맞지 않아요.';
      case 'IMAGE_DECODE_FAIL':
        return '이미지를 읽을 수 없어요.';
      default:
        return '인식에 실패했어요.';
    }
  }
}

class ExtractedResult extends AiResult {
  final List<List<int>> vectors;
  const ExtractedResult({required this.vectors});
}