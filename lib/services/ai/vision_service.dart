// vision_service.dart — Hybrid + X/Y RANSAC + gap 기반 threshold + 두 줄 인식
// =====================================================================
// ★ 변경점
//   두 줄 인식 추가: 셀들을 y중심값으로 클러스터링해서 줄 분리
//   - 1줄: 기존과 동일
//   - 2줄(이상): 각 줄별로 X/Y RANSAC + 6점 측정 독립 적용
//   - 출력: 위 줄(왼→오) + 아래 줄(왼→오) 순서로 concat
//
//   클러스터링: 단순 K-means style (1차원)
//     1) 셀 높이의 절반(셀높이*0.6)을 임계 gap으로 사용
//     2) y중심 정렬 후 인접 셀 간 y차가 임계 이상이면 줄 분리
//     3) 결과 줄 수가 2 이상이면 줄별 처리, 1이면 기존대로
// =====================================================================

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../utils/signal_utils.dart';

class CellComparison {
  final List<int> detected;
  final List<int> correct;
  final List<int> missing;
  final List<int> extra;
  final bool isCorrect;

  const CellComparison({
    required this.detected,
    required this.correct,
    required this.missing,
    required this.extra,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'detected': detected,
        'correct': correct,
        'missing': missing,
        'extra': extra,
        'is_correct': isCorrect,
      };
}

class VisionResult {
  final String result;
  final List<List<int>>? vectors;
  final List<CellComparison>? cells;
  final bool? allCorrect;
  final String? errorCode;
  final int? rowCount;  // ★ 검출된 줄 수

  const VisionResult({
    required this.result,
    this.vectors,
    this.cells,
    this.allCorrect,
    this.errorCode,
    this.rowCount,
  });

  Map<String, dynamic> toJson() => {
        'result': result,
        if (vectors != null) 'vectors': vectors,
        if (cells != null) 'cells': cells!.map((c) => c.toJson()).toList(),
        if (allCorrect != null) 'all_correct': allCorrect,
        if (errorCode != null) 'code': errorCode,
        if (rowCount != null) 'row_count': rowCount,
      };
}

class VisionService {
  static const double colLeftRatio = 0.32;
  static const double colRightRatio = 0.68;
  static const double rowTopRatio = 0.22;
  static const double rowMidRatio = 0.50;
  static const double rowBotRatio = 0.78;

  static const double roiRatio = 0.12;                  // 일반 셀 (점 위치 변동 흡수)
  static const double roiRatioExtrapolated = 0.10;       // 외삽 셀 (위치 부정확하므로 작게)
  static const double darkestPixelRatio = 0.10;

  static const double gapRelativeRatio = 1.3;
  static const double gapAbsoluteRatio = 0.10;

  static const double yCorrectionThreshold = 0.08;
  static const double xCorrectionThreshold = 0.10;

  // ★ 두 줄 분리 임계 (셀 높이의 60%)
  static const double rowSplitThresholdRatio = 0.6;

  VisionResult analyze({
    required List<List<double>> cellBoxes,
    required Uint8List imageBytes,
    List<List<int>>? answerVectors,
  }) {
    try {
      if (cellBoxes.isEmpty) {
        return const VisionResult(result: 'error', errorCode: 'NO_CELL_DETECTED');
      }
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return const VisionResult(result: 'error', errorCode: 'IMAGE_DECODE_FAIL');
      }

      // ★ 외삽: CNN이 양 끝 셀 누락 시 추정해서 추가
      final extrapolated = _extrapolateBoxes(cellBoxes, image);
      if (extrapolated.length != cellBoxes.length) {
        print('[Vision] 외삽 적용: ${cellBoxes.length}셀 → ${extrapolated.length}셀');
      }

      // ★ 1단계: 줄(row)로 분리
      final rows = _splitIntoRows(extrapolated);
      print('[Vision] 검출된 줄 수: ${rows.length}');

      // ★ 2단계: 각 줄별 처리 후 합치기
      final allVectors = <List<int>>[];
      int globalCellIdx = 0;

      for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        final row = rows[rowIdx];
        print('[Vision] === 줄 ${rowIdx + 1} 처리 (${row.length}셀) ===');

        // 줄 내에서 x순 정렬
        row.sort((a, b) => ((a[0] + a[2]) / 2).compareTo((b[0] + b[2]) / 2));
        // 줄 내에서 정규화
        final normalized = _normalizeBoxes(row);

        // ★ 줄 회전 각도 계산 (비스듬히 찍은 사진 보정)
        final rowAngle = _computeRowAngle(normalized);
        if (rowAngle.abs() > 0.017) { // 1도 이상이면 로그
          print('[Vision] 줄 회전각: ${(rowAngle * 180 / math.pi).toStringAsFixed(1)}도');
        }

        // 줄 내 6점 측정
        for (int i = 0; i < normalized.length; i++) {
          final bits = _sampleCell(image, normalized[i], globalCellIdx, rowAngle);
          allVectors.add(bits);
          print('[Vision] Cell ${globalCellIdx + 1}: $bits');
          globalCellIdx++;
        }
      }

      if (answerVectors == null) {
        return VisionResult(
          result: 'extracted',
          vectors: allVectors,
          rowCount: rows.length,
        );
      }
      if (allVectors.length != answerVectors.length) {
        return VisionResult(
          result: 'error',
          errorCode: 'CELL_COUNT_MISMATCH',
          rowCount: rows.length,
        );
      }

      final comparisons = <CellComparison>[];
      bool allCorrect = true;
      for (int i = 0; i < allVectors.length; i++) {
        final cmp = _compare(allVectors[i], answerVectors[i]);
        comparisons.add(cmp);
        if (!cmp.isCorrect) allCorrect = false;
      }

      return VisionResult(
        result: allCorrect ? 'match' : 'mismatch',
        vectors: allVectors,
        cells: comparisons,
        allCorrect: allCorrect,
        rowCount: rows.length,
      );
    } catch (e, st) {
      print('[Vision] 예외: $e\n$st');
      return const VisionResult(result: 'error', errorCode: 'EXCEPTION');
    }
  }

  // ───────────────────────────────────────────────────────────────────
  // ★ 외삽 (CNN 양 끝 셀 누락 보정)
  // ───────────────────────────────────────────────────────────────────
  // CNN이 첫/마지막 셀을 못 잡았을 때를 대비.
  // 검출된 셀들의 x중심 간격을 보고 양 끝 외부에 셀이 더 있는지 확인.
  // 그 위치의 6점을 측정해서 점이 1개라도 있으면 가상 셀 추가.
  List<List<double>> _extrapolateBoxes(
    List<List<double>> boxes,
    img.Image image,
  ) {
    if (boxes.length < 3) return boxes;

    // x순 정렬
    final sorted = [...boxes];
    sorted.sort((a, b) => ((a[0] + a[2]) / 2).compareTo((b[0] + b[2]) / 2));

    final cxs = sorted.map((b) => (b[0] + b[2]) / 2).toList();
    final widths = sorted.map((b) => b[2] - b[0]).toList()..sort();
    final heights = sorted.map((b) => b[3] - b[1]).toList()..sort();
    final medW = widths[widths.length ~/ 2];
    final medH = heights[heights.length ~/ 2];

    final gaps = <double>[];
    for (int i = 1; i < cxs.length; i++) {
      gaps.add(cxs[i] - cxs[i - 1]);
    }
    gaps.sort();
    final medGap = gaps[gaps.length ~/ 2];

    final firstCy = (sorted.first[1] + sorted.first[3]) / 2;
    final lastCy = (sorted.last[1] + sorted.last[3]) / 2;

    final result = [...sorted];

    // 왼쪽 외삽
    final leftCx = cxs.first - medGap;
    if (leftCx - medW / 2 > 0) {
      final hasDot = _cellLikelyExists(image, leftCx, firstCy, medW, medH);
      print('[Vision] 외삽 검사 좌측 (cx=${leftCx.toStringAsFixed(0)}): 점 ${hasDot ? "있음" : "없음"}');
      if (hasDot) {
        result.insert(0, [
          leftCx - medW / 2,
          firstCy - medH / 2,
          leftCx + medW / 2,
          firstCy + medH / 2,
          -1.0,  // ★ 외삽 셀 표시 (음수 confidence)
        ]);
      }
    }

    // 오른쪽 외삽
    final rightCx = cxs.last + medGap;
    if (rightCx + medW / 2 < image.width) {
      final hasDot = _cellLikelyExists(image, rightCx, lastCy, medW, medH);
      print('[Vision] 외삽 검사 우측 (cx=${rightCx.toStringAsFixed(0)}): 점 ${hasDot ? "있음" : "없음"}');
      if (hasDot) {
        result.add([
          rightCx - medW / 2,
          lastCy - medH / 2,
          rightCx + medW / 2,
          lastCy + medH / 2,
          -1.0,  // ★ 외삽 셀 표시
        ]);
      }
    }

    return result;
  }

  // 가상 셀 위치에 점이 있는지 검사 (1개라도 명백한 점이 있으면 true)
  bool _cellLikelyExists(
    img.Image image,
    double cx,
    double cy,
    double cw,
    double ch,
  ) {
    final positions = [
      [colLeftRatio, rowTopRatio],
      [colLeftRatio, rowMidRatio],
      [colLeftRatio, rowBotRatio],
      [colRightRatio, rowTopRatio],
      [colRightRatio, rowMidRatio],
      [colRightRatio, rowBotRatio],
    ];

    final x1 = (cx - cw / 2).toInt();
    final y1 = (cy - ch / 2).toInt();
    // 외삽 검사이므로 작은 ROI 사용 (인접 셀 침범 방지)
    final r = (math.min(cw, ch) * roiRatioExtrapolated).round();

    int dotCount = 0;
    for (final pos in positions) {
      final px = x1 + (cw * pos[0]).round();
      final py = y1 + (ch * pos[1]).round();

      final pixelVals = <double>[];
      for (int y = py - r; y <= py + r; y++) {
        for (int x = px - r; x <= px + r; x++) {
          if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
          final p = image.getPixel(x, y);
          pixelVals.add((p.r + p.g + p.b) / 3);
        }
      }

      if (pixelVals.length < 5) continue;
      pixelVals.sort();
      final cutoff = math.max(1, (pixelVals.length * darkestPixelRatio).round());
      double sumDark = 0;
      for (int j = 0; j < cutoff; j++) sumDark += pixelVals[j];
      final darkAvg = sumDark / cutoff;

      // 어두운 평균이 50 이하면 명백한 점
      if (darkAvg < 50) dotCount++;
    }

    return dotCount > 0;
  }

  // ───────────────────────────────────────────────────────────────────
  // ★ 줄 분리 (y중심값 기반 클러스터링)
  // ───────────────────────────────────────────────────────────────────
  List<List<List<double>>> _splitIntoRows(List<List<double>> boxes) {
    if (boxes.length < 2) return [List.from(boxes)];

    // 셀 높이 중앙값
    final heights = boxes.map((b) => b[3] - b[1]).toList()..sort();
    final medH = heights[heights.length ~/ 2];
    final splitGap = medH * rowSplitThresholdRatio;

    // y중심 + 인덱스 페어로 정렬
    final indexed = List.generate(boxes.length, (i) => i);
    indexed.sort((a, b) {
      final cyA = (boxes[a][1] + boxes[a][3]) / 2;
      final cyB = (boxes[b][1] + boxes[b][3]) / 2;
      return cyA.compareTo(cyB);
    });

    // 인접 셀 간 y차로 줄 분리
    final rows = <List<List<double>>>[];
    var currentRow = <List<double>>[];
    double? prevCy;

    for (final i in indexed) {
      final cy = (boxes[i][1] + boxes[i][3]) / 2;
      if (prevCy != null && (cy - prevCy) > splitGap) {
        rows.add(currentRow);
        currentRow = [];
      }
      currentRow.add(boxes[i]);
      prevCy = cy;
    }
    if (currentRow.isNotEmpty) rows.add(currentRow);

    print('[Vision] 줄 분리: 셀높이중앙값=${medH.toStringAsFixed(0)}px, 분리임계=${splitGap.toStringAsFixed(0)}px → ${rows.length}줄');
    for (int i = 0; i < rows.length; i++) {
      print('[Vision]   줄 ${i + 1}: ${rows[i].length}셀');
    }

    // ★ 노이즈 필터링: 셀 1개만 있는 줄은 CNN false positive로 간주
    //    (한 줄짜리 진짜 점자는 줄 분리되지 않으므로 안전)
    if (rows.length >= 2) {
      final filtered = rows.where((r) => r.length >= 2).toList();
      if (filtered.length < rows.length) {
        final removedCount = rows.length - filtered.length;
        print('[Vision] 노이즈 줄 ${removedCount}개 제거 (셀 1개 줄)');
        return filtered.isEmpty ? rows : filtered;
      }
    }
    return rows;
  }

  List<double>? _ransacFit(List<double> xs, List<double> ys, double refSize, String tag) {
    if (xs.length < 5) return null;

    final fit1 = polyfit2(xs, ys);
    final residuals = List<double>.generate(
      xs.length,
      (i) => (ys[i] - polyval2(fit1, xs[i])).abs(),
    );

    final sortedRes = [...residuals]..sort();
    final medRes = sortedRes[sortedRes.length ~/ 2];
    final absDevs = residuals.map((r) => (r - medRes).abs()).toList()..sort();
    final mad = absDevs[absDevs.length ~/ 2];
    final outlierThr = math.max(medRes + mad * 2.5, refSize * 0.05);

    final inlierXs = <double>[];
    final inlierYs = <double>[];
    final outlierIdx = <int>[];
    for (int i = 0; i < xs.length; i++) {
      if (residuals[i] <= outlierThr) {
        inlierXs.add(xs[i]);
        inlierYs.add(ys[i]);
      } else {
        outlierIdx.add(i);
      }
    }

    print('[Vision] $tag RANSAC: 잔차중앙값=${medRes.toStringAsFixed(0)}px, MAD=${mad.toStringAsFixed(0)}px, 임계=${outlierThr.toStringAsFixed(0)}px');

    if (inlierXs.length >= 3 && inlierXs.length >= xs.length * 0.7) {
      final fit2 = polyfit2(inlierXs, inlierYs);
      if (outlierIdx.isNotEmpty) {
        print('[Vision] $tag RANSAC: outlier 셀 ${outlierIdx.map((i) => i + 1).join(",")} 제외 (${inlierXs.length}/${xs.length})');
      } else {
        print('[Vision] $tag RANSAC: outlier 없음');
      }
      return fit2;
    } else {
      print('[Vision] $tag RANSAC: inlier 부족 (${inlierXs.length}/${xs.length}), 1차 fit 유지');
      return fit1;
    }
  }

  List<List<double>> _normalizeBoxes(List<List<double>> boxes) {
    if (boxes.length < 3) return boxes;

    final widths = boxes.map((b) => b[2] - b[0]).toList()..sort();
    final heights = boxes.map((b) => b[3] - b[1]).toList()..sort();
    final medW = widths[widths.length ~/ 2];
    final medH = heights[heights.length ~/ 2];

    final cxs = boxes.map((b) => (b[0] + b[2]) / 2).toList();
    final cys = boxes.map((b) => (b[1] + b[3]) / 2).toList();
    final indices = List<double>.generate(boxes.length, (i) => i.toDouble());

    double medGap = medW;
    if (cxs.length >= 2) {
      final gaps = List<double>.generate(cxs.length - 1, (i) => cxs[i + 1] - cxs[i])
        ..sort();
      medGap = gaps[gaps.length ~/ 2];
    }

    final cxFitCoef = _ransacFit(indices, cxs, medGap, 'X');
    final cyFitCoef = _ransacFit(cxs, cys, medH, 'Y');

    print('[Vision] 박스 정규화: 중앙값 크기=${medW.toStringAsFixed(0)}x${medH.toStringAsFixed(0)}, 셀간격=${medGap.toStringAsFixed(0)}px, x임계=${(medGap * xCorrectionThreshold).toStringAsFixed(0)}px, y임계=${(medH * yCorrectionThreshold).toStringAsFixed(0)}px');

    final normalized = <List<double>>[];
    for (int i = 0; i < boxes.length; i++) {
      var cx = cxs[i];
      var cy = cys[i];
      final oldW = boxes[i][2] - boxes[i][0];
      final oldH = boxes[i][3] - boxes[i][1];

      if (cxFitCoef != null) {
        final expectedCX = polyval2(cxFitCoef, i.toDouble());
        if ((cx - expectedCX).abs() > medGap * xCorrectionThreshold) {
          print('[Vision]   Cell ${i + 1} x중심 보정: ${cx.toStringAsFixed(0)} → ${expectedCX.toStringAsFixed(0)} (${(cx - expectedCX).abs().toStringAsFixed(0)}px 벗어남)');
          cx = expectedCX;
        }
      }

      double? expectedCY;
      if (cyFitCoef != null) {
        expectedCY = polyval2(cyFitCoef, cx);
      } else {
        if (i == 0 && boxes.length >= 3) {
          expectedCY = cys[1] + (cys[1] - cys[2]);
        } else if (i == boxes.length - 1 && boxes.length >= 3) {
          expectedCY = cys[i - 1] + (cys[i - 1] - cys[i - 2]);
        } else if (i > 0 && i < boxes.length - 1) {
          expectedCY = (cys[i - 1] + cys[i + 1]) / 2;
        }
      }

      final isExtrapCell = boxes[i].length > 4 && boxes[i][4] < 0;
      if (expectedCY != null && !isExtrapCell) {
        final diff = expectedCY - cy;
        // deadzone: 작은 보정은 무시 (직선 사진의 fit 오차로 멀쩡한 셀 흔들림 방지)
        // 큰 보정만 적용 (굴곡/어긋난 박스 교정)
        const deadzone = 12.0;
        if (diff.abs() >= deadzone) {
          final maxAdjust = medH * 0.10;
          final adjust = diff.clamp(-maxAdjust, maxAdjust);
          print('[Vision]   Cell ${i + 1} y중심 보정: ${cy.toStringAsFixed(0)} → ${(cy + adjust).toStringAsFixed(0)} (${adjust.toStringAsFixed(0)}px)');
          cy = cy + adjust;
        }
      }

      if ((oldW - medW).abs() / medW > 0.15 || (oldH - medH).abs() / medH > 0.15) {
        print('[Vision]   Cell ${i + 1} 크기 보정: ${oldW.toStringAsFixed(0)}x${oldH.toStringAsFixed(0)} → ${medW.toStringAsFixed(0)}x${medH.toStringAsFixed(0)}');
      }

      normalized.add([
        cx - medW / 2,
        cy - medH / 2,
        cx + medW / 2,
        cy + medH / 2,
        boxes[i].length > 4 ? boxes[i][4] : 1.0,
      ]);
    }
    return normalized;
  }

  // ───────────────────────────────────────────────────────────────────
  // ★ 줄 회전 각도 계산 (비스듬히 찍은 사진 보정)
  // ───────────────────────────────────────────────────────────────────
  // 셀 중심들의 기울기로 점자 줄 회전 각도를 구함.
  // 양 끝이 아닌 선형회귀로 구해 노이즈에 강함.
  double _computeRowAngle(List<List<double>> boxes) {
    if (boxes.length < 2) return 0.0;

    final cxs = <double>[];
    final cys = <double>[];
    for (final b in boxes) {
      cxs.add((b[0] + b[2]) / 2);
      cys.add((b[1] + b[3]) / 2);
    }

    // 선형회귀 기울기 (최소제곱)
    final n = cxs.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;
    for (int i = 0; i < n; i++) {
      sumX += cxs[i];
      sumY += cys[i];
      sumXY += cxs[i] * cys[i];
      sumXX += cxs[i] * cxs[i];
    }
    final denom = n * sumXX - sumX * sumX;
    if (denom.abs() < 1e-6) return 0.0;
    final slope = (n * sumXY - sumX * sumY) / denom;
    return math.atan(slope);
  }

  List<int> _sampleCell(
      img.Image image, List<double> cellBox, int cellIdx, double rowAngle) {
    final x1 = cellBox[0].clamp(0, image.width - 1.0).toInt();
    final y1 = cellBox[1].clamp(0, image.height - 1.0).toInt();
    final x2 = cellBox[2].clamp(0, image.width - 1.0).toInt();
    final y2 = cellBox[3].clamp(0, image.height - 1.0).toInt();
    final cw = x2 - x1;
    final ch = y2 - y1;

    // ★ 외삽 셀이면 작은 ROI 사용 (위치 부정확 → 인접 점 침범 방지)
    final isExtrapolated = cellBox.length > 4 && cellBox[4] < 0;
    final useRoiRatio = isExtrapolated ? roiRatioExtrapolated : roiRatio;
    print('[Vision]   Cell ${cellIdx + 1} box: ($x1,$y1)-($x2,$y2) size=${cw}x${ch}${isExtrapolated ? " [외삽]" : ""}');

    if (cw < 10 || ch < 10) return [0, 0, 0, 0, 0, 0];

    double cellSum = 0;
    int cellCount = 0;
    for (int y = y1; y < y2; y += 4) {
      for (int x = x1; x < x2; x += 4) {
        final p = image.getPixel(x, y);
        cellSum += (p.r + p.g + p.b) / 3;
        cellCount++;
      }
    }
    final cellAvg = cellCount > 0 ? cellSum / cellCount : 128.0;

    final positions = [
      [colLeftRatio, rowTopRatio],
      [colLeftRatio, rowMidRatio],
      [colLeftRatio, rowBotRatio],
      [colRightRatio, rowTopRatio],
      [colRightRatio, rowMidRatio],
      [colRightRatio, rowBotRatio],
    ];

    final r = (math.min(cw, ch) * useRoiRatio).round();
    // ★ 위치 보정용 search 반경 (외삽 셀은 위치 부정확하므로 제외)
    final searchRX = isExtrapolated ? 0 : (math.min(cw, ch) * 0.14).round();
    final searchRY = searchRX;
    final maxMoveX = (math.min(cw, ch) * 0.13);
    final maxMoveY = maxMoveX;
    final darkAvgs = <double>[];

    // ★ 회전 보정용 (셀 중심 기준 6점 위치를 rowAngle만큼 회전)
    final cosA = math.cos(rowAngle);
    final sinA = math.sin(rowAngle);
    final centerX = x1 + cw / 2.0;
    final centerY = y1 + ch / 2.0;

    for (int i = 0; i < 6; i++) {
      final pos = positions[i];
      // 셀 중심 기준 상대 위치
      final dx = cw * (pos[0] - 0.5);
      final dy = ch * (pos[1] - 0.5);
      // rowAngle 회전 (θ=0이면 그대로 → 직선 사진 회귀 없음)
      final rdx = dx * cosA - dy * sinA;
      final rdy = dx * sinA + dy * cosA;
      int cx = (centerX + rdx).round();
      int cy = (centerY + rdy).round();
      final origCx = cx, origCy = cy;

      // ★ ROI 위치 자동 보정: search 영역(X좁게/Y넓게)에서 명백한 점이 있으면 이동
      if (searchRX > 0 && searchRY > 0) {
        final searchVals = <double>[];
        final searchXs = <int>[];
        final searchYs = <int>[];
        for (int sy = math.max(0, cy - searchRY); sy <= cy + searchRY && sy < image.height; sy++) {
          for (int sx = math.max(0, cx - searchRX); sx <= cx + searchRX && sx < image.width; sx++) {
            final p = image.getPixel(sx, sy);
            searchVals.add((p.r + p.g + p.b) / 3);
            searchXs.add(sx);
            searchYs.add(sy);
          }
        }
        if (searchVals.isNotEmpty) {
          final indices = List<int>.generate(searchVals.length, (k) => k);
          indices.sort((a, b) => searchVals[a].compareTo(searchVals[b]));
          final topN = math.max(1, (searchVals.length * 0.05).round());
          double dark5Sum = 0, sumX = 0, sumY = 0;
          for (int j = 0; j < topN; j++) {
            final idx = indices[j];
            dark5Sum += searchVals[idx];
            sumX += searchXs[idx];
            sumY += searchYs[idx];
          }
          final dark5 = dark5Sum / topN;
          final newCx = (sumX / topN).round();
          final newCy = (sumY / topN).round();
          final moveX = (newCx - origCx).abs();
          final moveY = (newCy - origCy).abs();
          // 명백한 점(어두운 5% < 60) + X/Y 각각 이동 한도 내일 때만 보정
          if (dark5 < 60 && moveX <= maxMoveX && moveY <= maxMoveY) {
            cx = newCx;
            cy = newCy;
          }
        }
      }

      final pixelVals = <double>[];
      for (int y = cy - r; y <= cy + r; y++) {
        for (int x = cx - r; x <= cx + r; x++) {
          if (x < 0 || x >= image.width || y < 0 || y >= image.height) continue;
          final p = image.getPixel(x, y);
          pixelVals.add((p.r + p.g + p.b) / 3);
        }
      }

      double darkAvg = 255;
      if (pixelVals.isNotEmpty) {
        pixelVals.sort();
        final cutoff = math.max(1, (pixelVals.length * darkestPixelRatio).round());
        double sumDark = 0;
        for (int j = 0; j < cutoff; j++) sumDark += pixelVals[j];
        darkAvg = sumDark / cutoff;
      }
      darkAvgs.add(darkAvg);
    }

    final sortedAvgs = [...darkAvgs]..sort();
    final gaps = List<double>.generate(5, (i) => sortedAvgs[i + 1] - sortedAvgs[i]);
    final avgGap = gaps.reduce((a, b) => a + b) / 5;
    final gapThrRelative = avgGap * gapRelativeRatio;
    final gapThrAbsolute = cellAvg * gapAbsoluteRatio;

    // ★ split 결정: 가장 큰 gap 우선 (두번째 큰 gap의 2배 이상일 때)
    //              그렇지 않으면 가장 오른쪽 (기존 동작)
    final candidates = <int>[];
    for (int i = 0; i < 5; i++) {
      if (gaps[i] >= gapThrRelative && gaps[i] >= gapThrAbsolute) {
        candidates.add(i);
      }
    }

    int splitPos = -1;
    if (candidates.length == 1) {
      splitPos = candidates[0];
    } else if (candidates.length >= 2) {
      // 가장 큰 + 두번째 큰 찾기
      int maxIdx = candidates[0];
      for (final i in candidates) {
        if (gaps[i] > gaps[maxIdx]) maxIdx = i;
      }
      int secondIdx = -1;
      for (final i in candidates) {
        if (i == maxIdx) continue;
        if (secondIdx == -1 || gaps[i] > gaps[secondIdx]) secondIdx = i;
      }

      // 가장 큰이 두번째의 2배 이상이면 → 가장 큰
      if (secondIdx == -1 || gaps[maxIdx] >= gaps[secondIdx] * 2.0) {
        splitPos = maxIdx;
      } else {
        // 그렇지 않으면 가장 오른쪽
        splitPos = candidates.reduce((a, b) => a > b ? a : b);
      }
    }

    List<int> bits;
    String mode;
    if (splitPos >= 0) {
      final threshold = (sortedAvgs[splitPos] + sortedAvgs[splitPos + 1]) / 2;
      bits = darkAvgs.map((v) => v < threshold ? 1 : 0).toList();
      mode = 'gap@${splitPos + 1} (점 ${splitPos + 1}개), threshold=${threshold.toStringAsFixed(0)}';
    } else {
      bits = [0, 0, 0, 0, 0, 0];
      mode = '빈셀 (큰 gap 없음)';
    }

    print('[Vision]   셀평균=${cellAvg.toStringAsFixed(0)}, gaps=${gaps.map((g) => g.toStringAsFixed(0)).join(",")}, gap임계=${math.max(gapThrRelative, gapThrAbsolute).toStringAsFixed(0)} → $mode');
    print('[Vision]   어두운30%=${darkAvgs.map((b) => b.toStringAsFixed(0)).join(", ")}');
    return bits;
  }

  CellComparison _compare(List<int> detected, List<int> correct) {
    final missing = <int>[];
    final extra = <int>[];
    for (int i = 0; i < 6; i++) {
      if (correct[i] == 1 && detected[i] == 0) missing.add(i + 1);
      if (correct[i] == 0 && detected[i] == 1) extra.add(i + 1);
    }
    return CellComparison(
      detected: detected,
      correct: correct,
      missing: missing,
      extra: extra,
      isCorrect: missing.isEmpty && extra.isEmpty,
    );
  }

  // ★ 디버그 시각화 (줄별 색상 다르게)
  Uint8List? debugVisualize(Uint8List imageBytes, List<List<double>> cellBoxes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // ★ 외삽 적용 (analyze()와 동일 처리)
    final extrapolated = _extrapolateBoxes(cellBoxes, image);
    final rows = _splitIntoRows(extrapolated);
    final rowColors = [
      img.ColorRgb8(0, 255, 0),    // 줄1: 녹색
      img.ColorRgb8(0, 200, 255),  // 줄2: 청록
      img.ColorRgb8(255, 200, 0),  // 줄3: 노랑
    ];

    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx];
      row.sort((a, b) => ((a[0] + a[2]) / 2).compareTo((b[0] + b[2]) / 2));
      final normalized = _normalizeBoxes(row);
      final color = rowColors[rowIdx % rowColors.length];

      // ★ 줄 회전각 (analyze와 동일)
      final rowAngle = _computeRowAngle(normalized);
      final cosA = math.cos(rowAngle);
      final sinA = math.sin(rowAngle);

      for (final cell in normalized) {
        final x1 = cell[0].clamp(0, image.width - 1.0).toInt();
        final y1 = cell[1].clamp(0, image.height - 1.0).toInt();
        final x2 = cell[2].clamp(0, image.width - 1.0).toInt();
        final y2 = cell[3].clamp(0, image.height - 1.0).toInt();
        final cw = x2 - x1;
        final ch = y2 - y1;

        // 외삽 셀 표시
        final isExtrapolated = cell.length > 4 && cell[4] < 0;
        final useRoiRatio = isExtrapolated ? roiRatioExtrapolated : roiRatio;

        final thickness = math.max(3, (math.min(cw, ch) / 100).round());
        img.drawRect(image,
            x1: x1, y1: y1, x2: x2, y2: y2,
            color: color,
            thickness: thickness);

        final r = (math.min(cw, ch) * useRoiRatio).round();
        final centerX = x1 + cw / 2.0;
        final centerY = y1 + ch / 2.0;
        final positions = [
          [colLeftRatio, rowTopRatio],
          [colLeftRatio, rowMidRatio],
          [colLeftRatio, rowBotRatio],
          [colRightRatio, rowTopRatio],
          [colRightRatio, rowMidRatio],
          [colRightRatio, rowBotRatio],
        ];
        for (final pos in positions) {
          // 셀 중심 기준 회전 (analyze와 동일)
          final dx = cw * (pos[0] - 0.5);
          final dy = ch * (pos[1] - 0.5);
          final cx = (centerX + dx * cosA - dy * sinA).round();
          final cy = (centerY + dx * sinA + dy * cosA).round();
          img.fillCircle(image,
              x: cx, y: cy, radius: r,
              color: img.ColorRgb8(255, 0, 0));
        }
      }
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 80));
  }
}