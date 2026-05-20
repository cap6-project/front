import 'package:flutter/material.dart';
import 'package:puzzle_dot/models/camera_initialization_result.dart';

/// 카메라 사용 불가 안내 화면
///
/// 역할:
/// - 카메라 없음 상태 UI 표시
/// - 카메라 초기화 실패 UI 표시
/// - 다시 확인 / 홈 이동 액션 제공
///
/// 권한 거부 화면과 의미 분리
class CameraUnavailableView extends StatelessWidget {
  final CameraInitializationResult? reason;
  final Future<void> Function() onRetry;
  final VoidCallback onHome;

  const CameraUnavailableView({
    super.key,
    required this.reason,
    required this.onRetry,
    required this.onHome,
  });

  String get _title {
    if (reason == CameraInitializationResult.noCamera) {
      return '카메라를 찾을 수 없습니다';
    }

    return '카메라를 사용할 수 없습니다';
  }

  String get _description {
    if (reason == CameraInitializationResult.noCamera) {
      return '현재 기기 또는 에뮬레이터에서 카메라를 찾을 수 없습니다.\n실제 기기에서 다시 확인해주세요.';
    }

    return '카메라 초기화에 실패했습니다.\n권한과 기기 상태를 확인한 뒤 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('camera_unavailable'),
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 74,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 28),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              Semantics(
                button: true,
                label: '카메라 다시 확인',
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      '다시 확인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: '홈으로 돌아가기',
                child: SizedBox(
                  height: 54,
                  child: TextButton.icon(
                    onPressed: onHome,
                    icon: const Icon(Icons.home_outlined),
                    label: const Text(
                      '홈으로 돌아가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}