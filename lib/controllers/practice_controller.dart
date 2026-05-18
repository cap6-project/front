import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:puzzle_dot/services/camera_service.dart';
import 'package:puzzle_dot/services/permission_service.dart';

enum PracticeCameraStatus {
  checking,
  permissionDenied,
  unavailable,
  ready,
}

/// Practice 화면 상태 컨트롤러
///
/// 역할:
/// - 카메라 권한 확인
/// - 카메라 초기화
/// - 촬영 요청
/// - 화면에 필요한 상태만 노출
///
/// UI는 CameraService, PermissionService 직접 호출하지 않음
class PracticeController extends ChangeNotifier {
  final CameraService _cameraService;

  PracticeController({
    CameraService? cameraService,
  }) : _cameraService = cameraService ?? CameraService();

  PracticeCameraStatus _status = PracticeCameraStatus.checking;
  bool _isPreparing = false;
  bool _isCapturing = false;

  PracticeCameraStatus get status => _status;
  bool get isPreparing => _isPreparing;
  bool get isCapturing => _isCapturing;
  CameraController? get cameraController => _cameraService.controller;

  /// 권한 확인 후 카메라 준비
  ///
  /// Practice 화면 진입 또는 다시 확인 버튼에서만 호출
  Future<void> prepare() async {
    if (_isPreparing) return;

    _isPreparing = true;
    _setStatus(PracticeCameraStatus.checking);

    final granted = await PermissionService.requestCamera();
    if (!granted) {
      _isPreparing = false;
      _setStatus(PracticeCameraStatus.permissionDenied);
      return;
    }

    final initialized = await _cameraService.initialize();
    _isPreparing = false;

    if (!initialized) {
      _setStatus(PracticeCameraStatus.unavailable);
      return;
    }

    _setStatus(PracticeCameraStatus.ready);
  }

  /// 촬영 요청
  ///
  /// 실제 AI/OpenCV 분석 연결 전까지는 이미지 경로만 반환
  Future<String?> capture() async {
    if (_isCapturing) return null;

    _isCapturing = true;
    notifyListeners();

    final imagePath = await _cameraService.capture();

    _isCapturing = false;
    notifyListeners();

    return imagePath;
  }

  void _setStatus(PracticeCameraStatus nextStatus) {
    if (_status == nextStatus) return;

    _status = nextStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}