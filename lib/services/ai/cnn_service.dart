// cnn_service.dart — Cell Detector + 좌표 스케일 복원 + 셀 dedup
// =====================================================================
// ★ 변경점:
//   useDedup=true 활성화. 셀이 인접 거리 미만이면 score 높은 쪽만 유지.
//   한 셀이 두 박스로 잡히는 false positive 방지.
// =====================================================================

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class YoloDetector {
  final String modelPath;
  final double confThreshold;
  final double iouThreshold;
  final int inputSize;
  final String tag;
  final bool useDedup;

  Interpreter? _interpreter;
  bool _isLoaded = false;

  YoloDetector({
    required this.modelPath,
    required this.tag,
    this.confThreshold = 0.25,
    this.iouThreshold = 0.45,
    this.inputSize = 640,
    this.useDedup = false,
  });

  Future<bool> loadModel() async {
    if (_isLoaded) return true;
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isLoaded = true;
      print('[$tag] 모델 로드 성공');
      return true;
    } catch (e) {
      print('[$tag] 모델 로드 실패: $e');
      return false;
    }
  }

  Future<List<List<double>>> detect(
    Uint8List imageBytes, {
    int scaledMaxDim = 1280,
  }) async {
    if (!_isLoaded || _interpreter == null) return [];
    try {
      var decoded = img.decodeImage(imageBytes);
      if (decoded == null) return [];

      final origW = decoded.width;
      final origH = decoded.height;
      double scale = 1.0;

      if (decoded.width > scaledMaxDim || decoded.height > scaledMaxDim) {
        if (decoded.width > decoded.height) {
          scale = scaledMaxDim / decoded.width;
          decoded = img.copyResize(decoded, width: scaledMaxDim);
        } else {
          scale = scaledMaxDim / decoded.height;
          decoded = img.copyResize(decoded, height: scaledMaxDim);
        }
        print('[$tag] 리사이즈: ${origW}x${origH} → ${decoded.width}x${decoded.height} (scale=${scale.toStringAsFixed(3)})');
      }

      final boxes = _runOnImage(decoded);

      if (scale != 1.0) {
        for (final box in boxes) {
          box[0] = box[0] / scale;
          box[1] = box[1] / scale;
          box[2] = box[2] / scale;
          box[3] = box[3] / scale;
        }
        print('[$tag] 좌표 복원 완료 (×${(1.0 / scale).toStringAsFixed(3)})');
      }

      return boxes;
    } catch (e, st) {
      print('[$tag] 추론 실패: $e\n$st');
      return [];
    }
  }

  List<List<double>> _runOnImage(img.Image source) {
    final origW = source.width;
    final origH = source.height;

    final scale = math.min(inputSize / origW, inputSize / origH);
    final newW = (origW * scale).round();
    final newH = (origH * scale).round();
    final padX = (inputSize - newW) ~/ 2;
    final padY = (inputSize - newH) ~/ 2;

    final resized = img.copyResize(source, width: newW, height: newH);
    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(114, 114, 114));
    img.compositeImage(canvas, resized, dstX: padX, dstY: padY);

    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = canvas.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          },
        ),
      ),
    );

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.filled(
      outputShape.reduce((a, b) => a * b),
      0.0,
    ).reshape(outputShape);

    _interpreter!.run(input, output);

    final out = output[0] as List;
    final numDetections = (out[0] as List).length;

    final boxes = <List<double>>[];
    for (int i = 0; i < numDetections; i++) {
      final score = (out[4][i] as num).toDouble();
      if (score < confThreshold) continue;

      double cx = (out[0][i] as num).toDouble() * inputSize;
      double cy = (out[1][i] as num).toDouble() * inputSize;
      double w = (out[2][i] as num).toDouble() * inputSize;
      double h = (out[3][i] as num).toDouble() * inputSize;

      final x1 = ((cx - w / 2) - padX) / scale;
      final y1 = ((cy - h / 2) - padY) / scale;
      final x2 = ((cx + w / 2) - padX) / scale;
      final y2 = ((cy + h / 2) - padY) / scale;

      final cx1 = x1.clamp(0.0, origW.toDouble());
      final cy1 = y1.clamp(0.0, origH.toDouble());
      final cx2 = x2.clamp(0.0, origW.toDouble());
      final cy2 = y2.clamp(0.0, origH.toDouble());

      if (cx2 - cx1 < 3 || cy2 - cy1 < 3) continue;
      boxes.add([cx1, cy1, cx2, cy2, score]);
    }

    var filtered = _nms(boxes, iouThreshold);
    if (useDedup) filtered = _strongDedup(filtered);
    return filtered;
  }

  List<List<double>> _nms(List<List<double>> boxes, double iouThr) {
    if (boxes.isEmpty) return [];
    boxes.sort((a, b) => b[4].compareTo(a[4]));
    final keep = <List<double>>[];
    final suppressed = List<bool>.filled(boxes.length, false);
    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      keep.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(boxes[i], boxes[j]) > iouThr) suppressed[j] = true;
      }
    }
    return keep;
  }

  /// ★ Strong Dedup
  /// 평균 박스 크기를 계산하고, 박스 중심점들이 minDist 이하로 가까우면
  /// score 높은 쪽만 유지. 한 셀이 두 박스로 잡히는 false positive 방지.
  List<List<double>> _strongDedup(List<List<double>> boxes) {
    if (boxes.isEmpty) return [];
    double avgSize = 0;
    for (final b in boxes) {
      avgSize += math.min(b[2] - b[0], b[3] - b[1]);
    }
    avgSize /= boxes.length;
    final minDist = avgSize * 0.7; // 평균 크기의 70% 이상 떨어져야 별도 셀
    print('[$tag] dedup: 평균크기=${avgSize.toStringAsFixed(0)}, 최소거리=${minDist.toStringAsFixed(0)}');

    boxes.sort((a, b) => b[4].compareTo(a[4]));
    final keep = <List<double>>[];
    int removed = 0;
    for (final b in boxes) {
      final cx = (b[0] + b[2]) / 2;
      final cy = (b[1] + b[3]) / 2;
      bool tooClose = false;
      for (final k in keep) {
        final kcx = (k[0] + k[2]) / 2;
        final kcy = (k[1] + k[3]) / 2;
        final dist = math.sqrt((cx - kcx) * (cx - kcx) + (cy - kcy) * (cy - kcy));
        if (dist < minDist) { tooClose = true; break; }
      }
      if (!tooClose) {
        keep.add(b);
      } else {
        removed++;
      }
    }
    if (removed > 0) {
      print('[$tag] dedup으로 $removed개 박스 제거');
    }
    return keep;
  }

  double _iou(List<double> a, List<double> b) {
    final x1 = math.max(a[0], b[0]);
    final y1 = math.max(a[1], b[1]);
    final x2 = math.min(a[2], b[2]);
    final y2 = math.min(a[3], b[3]);
    if (x2 <= x1 || y2 <= y1) return 0;
    final inter = (x2 - x1) * (y2 - y1);
    final areaA = (a[2] - a[0]) * (a[3] - a[1]);
    final areaB = (b[2] - b[0]) * (b[3] - b[1]);
    return inter / (areaA + areaB - inter);
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}

class CnnService {
  final _cellDetector = YoloDetector(
    modelPath: 'assets/models/cell_detector.tflite',
    tag: 'CELL',
    confThreshold: 0.3,
    iouThreshold: 0.45,
    useDedup: true, // ★ 셀 dedup 활성화 (한 셀이 두 박스로 잡히는 문제 방지)
  );

  Future<bool> loadModels() async {
    final c = await _cellDetector.loadModel();
    print('[CNN] 셀: ${c ? "OK" : "FAIL"}');
    return c;
  }

  Future<List<List<double>>> detectCells(Uint8List imageBytes) async {
    final boxes = await _cellDetector.detect(imageBytes);
    print('[CELL] 검출: ${boxes.length}개');
    return boxes;
  }

  void dispose() {
    _cellDetector.dispose();
  }
}