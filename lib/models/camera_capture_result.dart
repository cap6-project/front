/// 카메라 촬영 결과 모델
///
/// 역할:
/// - 촬영 성공/실패 상태 표현
/// - 촬영 이미지 경로 전달
/// - 실패 사유 전달
///
/// 실제 AI/OpenCV 분석 연결 전 공통 결과 타입
class CameraCaptureResult {
  final bool isSuccess;
  final String? imagePath;
  final String? message;

  const CameraCaptureResult._({
    required this.isSuccess,
    this.imagePath,
    this.message,
  });

  factory CameraCaptureResult.success(String imagePath) {
    return CameraCaptureResult._(
      isSuccess: true,
      imagePath: imagePath,
    );
  }

  factory CameraCaptureResult.failure(String message) {
    return CameraCaptureResult._(
      isSuccess: false,
      message: message,
    );
  }
}