import 'package:camera/camera.dart';
import 'package:puzzle_dot/models/camera_initialization_result.dart';

/// 카메라 접근 서비스
///
/// 역할:
/// - 사용 가능한 카메라 조회
/// - 카메라 컨트롤러 초기화
/// - 촬영 요청 처리
/// - 카메라 자원 해제
///
/// 화면은 camera 패키지에 직접 의존하지 않고 이 서비스를 통해 접근
class CameraService {
  CameraController? _controller;

  bool get isReady => _controller?.value.isInitialized == true;
  CameraController? get controller => _controller;

  /// 후면 카메라 우선 초기화
  ///
  /// 카메라 없음/초기화 실패를 분리해서 반환
  Future<CameraInitializationResult> initializeWithResult() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return CameraInitializationResult.noCamera;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      return CameraInitializationResult.success;
    } catch (_) {
      return CameraInitializationResult.initializeFailed;
    }
  }

  /// 기존 bool 흐름 호환용
  ///
  /// 새 코드는 initializeWithResult 사용 권장
  Future<bool> initialize() async {
    final result = await initializeWithResult();
    return result.isSuccess;
  }

  /// 정지 이미지 촬영
  ///
  /// 준비 전 또는 촬영 실패 시 null 반환
  Future<String?> capture() async {
    if (!isReady) return null;

    try {
      final file = await _controller!.takePicture();
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// 카메라 자원 해제
  ///
  /// 화면 dispose 시 controller 누수 방지
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}