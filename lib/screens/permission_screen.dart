import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_dot/services/permission_service.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPermissionView(
        onRetry: () async {},
        onHome: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    );
  }
}

/// 카메라 권한 안내 전용 화면
///
/// 역할:
/// - 권한 안내 UI 표시
/// - 권한 안내 TTS 실행
/// - 다시 확인 TTS 실행
///
/// 실제 권한 재확인 로직은 onRetry로 외부에서 주입
class CameraPermissionView extends StatefulWidget {
  final Future<void> Function() onRetry;
  final VoidCallback onHome;

  const CameraPermissionView({
    super.key,
    required this.onRetry,
    required this.onHome,
  });

  @override
  State<CameraPermissionView> createState() => _CameraPermissionViewState();
}

class _CameraPermissionViewState extends State<CameraPermissionView> {
  final AppTtsService _tts = AppTtsService();

  bool _isRetrying = false;
  bool _hasSpokenInitialGuide = false;

  @override
  void initState() {
    super.initState();

    /// 화면이 실제로 그려진 뒤 최초 1회만 TTS 실행
    ///
    /// Practice/카메라 학습 진입 시에만 이 위젯이 생성되어야 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakInitialGuide();
    });
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _speakInitialGuide() async {
    if (_hasSpokenInitialGuide) return;

    _hasSpokenInitialGuide = true;
    await _tts.speak(TtsScriptProvider.cameraPermissionRequired);
  }

  Future<void> _retryPermissionCheck() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    await _tts.speak(TtsScriptProvider.cameraPermissionRetry);
    await widget.onRetry();

    if (!mounted) return;

    setState(() => _isRetrying = false);
  }

  Future<void> _openSettings() async {
    await PermissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 72,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 28),
              const Text(
                '카메라 권한이 필요합니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '점자 학습을 위해 카메라 접근 권한이 필요합니다.\n설정에서 권한을 허용한 뒤 다시 확인해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              Semantics(
                button: true,
                label: _isRetrying ? '카메라 권한 확인 중' : '카메라 권한 다시 확인',
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _retryPermissionCheck,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isRetrying ? '확인 중...' : '다시 확인',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93C5FD),
                      disabledForegroundColor: Colors.white,
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
                label: '설정으로 이동',
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isRetrying ? null : _openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text(
                      '설정으로 이동',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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
                    onPressed: _isRetrying ? null : widget.onHome,
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
                      disabledForegroundColor: const Color(0xFFCBD5E1),
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