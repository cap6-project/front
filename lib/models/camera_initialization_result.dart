/// 카메라 초기화 결과
///
/// bool 반환만으로는 카메라 없음/초기화 실패 구분 어려움
/// PracticeController가 화면 상태를 더 정확히 결정할 수 있도록 분리
enum CameraInitializationResult {
  success,
  noCamera,
  initializeFailed,
}

extension CameraInitializationResultX on CameraInitializationResult {
  bool get isSuccess => this == CameraInitializationResult.success;
}