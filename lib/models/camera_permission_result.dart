/// 카메라 권한 확인 결과
///
/// PermissionService가 permission_handler 결과를 앱 내부 상태로 변환
/// 화면과 컨트롤러는 permission_handler 패키지 타입을 직접 알지 않음
enum CameraPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

extension CameraPermissionResultX on CameraPermissionResult {
  bool get isGranted => this == CameraPermissionResult.granted;

  bool get isDenied {
    return this == CameraPermissionResult.denied ||
        this == CameraPermissionResult.permanentlyDenied;
  }
}