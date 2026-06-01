// signal_utils.dart — 신호 처리 유틸 (find_peaks Dart 구현)
// =====================================================================
// scipy.signal.find_peaks를 Dart로 직접 구현.
// ai.py에서 봉우리 검출에 사용.

import 'dart:math' as math;

class PeakResult {
  final List<int> indices;
  final List<double> prominences;
  const PeakResult({required this.indices, required this.prominences});
}

/// 1D 신호에서 봉우리 검출.
/// scipy.signal.find_peaks와 유사:
///   - [distance]: 봉우리 간 최소 거리
///   - [prominence]: 최소 prominence (봉우리 두드러짐 정도)
PeakResult findPeaks(List<double> signal,
    {int? distance, double? prominence}) {
  final n = signal.length;
  if (n < 3) return const PeakResult(indices: [], prominences: []);

  // 1. 모든 로컬 max 찾기
  final List<int> candidates = [];
  for (int i = 1; i < n - 1; i++) {
    if (signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
      candidates.add(i);
    } else if (signal[i] > signal[i - 1] && signal[i] == signal[i + 1]) {
      // 평지(plateau) 처리: 끝지점만 채택
      int j = i + 1;
      while (j < n - 1 && signal[j] == signal[i]) j++;
      if (j < n && signal[j] < signal[i]) {
        candidates.add((i + j - 1) ~/ 2);
      }
      i = j;
    }
  }

  if (candidates.isEmpty) return const PeakResult(indices: [], prominences: []);

  // 2. Prominence 계산
  final List<double> proms = [];
  for (final p in candidates) {
    // 왼쪽: 더 높은 점 또는 시작까지의 최솟값
    double leftMin = signal[p];
    for (int i = p - 1; i >= 0; i--) {
      if (signal[i] > signal[p]) break;
      if (signal[i] < leftMin) leftMin = signal[i];
    }
    // 오른쪽: 더 높은 점 또는 끝까지의 최솟값
    double rightMin = signal[p];
    for (int i = p + 1; i < n; i++) {
      if (signal[i] > signal[p]) break;
      if (signal[i] < rightMin) rightMin = signal[i];
    }
    proms.add(signal[p] - math.max(leftMin, rightMin));
  }

  // 3. Prominence 필터
  List<int> idx = List.generate(candidates.length, (i) => i);
  if (prominence != null) {
    idx = idx.where((i) => proms[i] >= prominence).toList();
  }

  // 4. Distance 필터 — 작은 prominence부터 제거
  if (distance != null && distance > 0) {
    // prominence 큰 순으로 정렬해서 처리
    idx.sort((a, b) => proms[b].compareTo(proms[a]));
    final keep = <int>{};
    for (final i in idx) {
      bool conflicts = false;
      for (final j in keep) {
        if ((candidates[i] - candidates[j]).abs() < distance) {
          conflicts = true;
          break;
        }
      }
      if (!conflicts) keep.add(i);
    }
    idx = keep.toList();
  }

  // 5. 인덱스 순으로 정렬
  idx.sort((a, b) => candidates[a].compareTo(candidates[b]));

  return PeakResult(
    indices: idx.map((i) => candidates[i]).toList(),
    prominences: idx.map((i) => proms[i]).toList(),
  );
}


/// 1D Gaussian blur (kernel size k, odd)
List<double> gaussianBlur1D(List<double> signal, int k) {
  if (k % 2 == 0) k += 1;
  final n = signal.length;
  if (k < 3) return List<double>.from(signal);
  // Gaussian kernel
  final sigma = k / 6.0;
  final half = k ~/ 2;
  final kernel = List<double>.generate(k, (i) {
    final x = (i - half).toDouble();
    return math.exp(-(x * x) / (2 * sigma * sigma));
  });
  final ksum = kernel.fold<double>(0, (a, b) => a + b);
  for (int i = 0; i < k; i++) kernel[i] /= ksum;

  final out = List<double>.filled(n, 0);
  for (int i = 0; i < n; i++) {
    double s = 0;
    for (int j = 0; j < k; j++) {
      int idx = i + j - half;
      if (idx < 0) idx = 0;
      if (idx >= n) idx = n - 1;
      s += signal[idx] * kernel[j];
    }
    out[i] = s;
  }
  return out;
}


/// 1D 신호의 평균
double mean(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}


/// 1D 신호의 표준편차
double stdDev(List<double> values) {
  if (values.length < 2) return 0;
  final m = mean(values);
  final s = values.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b);
  return math.sqrt(s / values.length);
}


/// 1D 신호의 median
double median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final n = sorted.length;
  if (n % 2 == 1) return sorted[n ~/ 2];
  return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}


/// 2차 다항식 fit (least squares)
/// [x], [y]: 데이터 포인트
/// return: [a, b, c] (y = a*x^2 + b*x + c)
List<double> polyfit2(List<double> x, List<double> y) {
  if (x.length != y.length || x.length < 3) {
    return [0, 0, mean(y)];
  }
  final n = x.length;
  double sx = 0, sx2 = 0, sx3 = 0, sx4 = 0;
  double sy = 0, sxy = 0, sx2y = 0;
  for (int i = 0; i < n; i++) {
    final xi = x[i], yi = y[i];
    final xi2 = xi * xi;
    sx += xi;
    sx2 += xi2;
    sx3 += xi2 * xi;
    sx4 += xi2 * xi2;
    sy += yi;
    sxy += xi * yi;
    sx2y += xi2 * yi;
  }
  // 정규방정식
  // [sx4 sx3 sx2] [a]   [sx2y]
  // [sx3 sx2 sx ] [b] = [sxy ]
  // [sx2 sx  n  ] [c]   [sy  ]
  final det = sx4 * (sx2 * n - sx * sx) -
      sx3 * (sx3 * n - sx * sx2) +
      sx2 * (sx3 * sx - sx2 * sx2);
  if (det.abs() < 1e-10) return [0, 0, mean(y)];

  final a = (sx2y * (sx2 * n - sx * sx) -
          sxy * (sx3 * n - sx * sx2) +
          sy * (sx3 * sx - sx2 * sx2)) /
      det;
  final b = (sx4 * (sxy * n - sx * sy) -
          sx3 * (sx2y * n - sx2 * sy) +
          sx2 * (sx2y * sx - sxy * sx2)) /
      det;
  final c = (sx4 * (sx2 * sy - sx * sxy) -
          sx3 * (sx3 * sy - sx * sx2y) +
          sx2 * (sx3 * sxy - sx2 * sx2y)) /
      det;
  return [a, b, c];
}


/// 다항식 평가: y = a*x^2 + b*x + c
double polyval2(List<double> coef, double x) {
  return coef[0] * x * x + coef[1] * x + coef[2];
}
