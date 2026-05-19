enum LearningCaptureSourceType {
  galleryMock,
  camera,
}

/// 학습 분석 입력 이미지 정보
///
/// 역할:
/// - 이미지 경로 전달
/// - 갤러리 mock / 실제 카메라 촬영 출처 구분
/// - 추후 AI/OpenCV 분석 로그와 연결
class LearningCaptureSource {
  final String imagePath;
  final LearningCaptureSourceType type;

  const LearningCaptureSource({
    required this.imagePath,
    required this.type,
  });

  bool get isMock => type == LearningCaptureSourceType.galleryMock;
  bool get isCamera => type == LearningCaptureSourceType.camera;

  factory LearningCaptureSource.galleryMock(String imagePath) {
    return LearningCaptureSource(
      imagePath: imagePath,
      type: LearningCaptureSourceType.galleryMock,
    );
  }

  factory LearningCaptureSource.camera(String imagePath) {
    return LearningCaptureSource(
      imagePath: imagePath,
      type: LearningCaptureSourceType.camera,
    );
  }
}