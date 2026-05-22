import 'package:permission_handler/permission_handler.dart';
import 'package:puzzle_dot/models/camera_permission_result.dart';

/// 카메라 권한 서비스
///
/// 역할:
/// - permission_handler 결과를 앱 내부 enum으로 변환
/// - 화면/컨트롤러가 외부 패키지 타입에 직접 의존하지 않도록 분리
abstract class PermissionService {
  PermissionService._();

  /// 카메라 권한 요청
  ///
  /// 사용자가 확인/다시확인 버튼을 눌렀을 때만 호출
  static Future<CameraPermissionResult> requestCamera() async {
    final status = await Permission.camera.request();
    return _mapStatus(status);
  }

  /// 현재 카메라 권한 상태 확인
  ///
  /// 권한 팝업을 띄우지 않고 현재 상태만 조회
  static Future<CameraPermissionResult> checkCamera() async {
    final status = await Permission.camera.status;
    return _mapStatus(status);
  }

  /// 앱 설정 화면 열기
  ///
  /// permanentlyDenied 상태에서 사용
  static Future<void> openSettings() => openAppSettings();

  static CameraPermissionResult _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return CameraPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return CameraPermissionResult.permanentlyDenied;
    }

    return CameraPermissionResult.denied;
  }
}