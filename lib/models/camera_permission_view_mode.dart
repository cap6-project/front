/// 카메라 권한 안내 화면 모드
///
/// UI가 bool 값으로 상태 의미를 추측하지 않도록 분리
/// 최초 확인과 권한 거절 후 재확인을 명확하게 구분
enum CameraPermissionViewMode {
  initial,
  denied,
}