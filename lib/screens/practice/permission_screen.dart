import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_dot/models/camera_permission_view_mode.dart';
import 'package:puzzle_dot/services/permission/permission_service.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraPermissionView(
        mode: CameraPermissionViewMode.initial,
        onConfirm: () async {},
        onHome: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
    );
  }
}

/// 카메라 권한 안내 전용 화면
///
/// 역할:
/// - 최초 권한 확인 UI 표시
/// - 권한 거절 후 재확인 UI 표시
/// - 권한 안내/재확인 TTS 실행
class CameraPermissionView extends StatefulWidget {
  final CameraPermissionViewMode mode;
  final Future<void> Function() onConfirm;
  final VoidCallback onHome;

  const CameraPermissionView({
    super.key,
    required this.mode,
    required this.onConfirm,
    required this.onHome,
  });

  @override
  State<CameraPermissionView> createState() => _CameraPermissionViewState();
}

class _CameraPermissionViewState extends State<CameraPermissionView> {
  final AppTtsService _tts = AppTtsService();

  bool _isChecking = false;
  bool _hasSpokenInitialGuide = false;

  /// 최초 확인 클릭 시 확인 중 UI 최소 노출 시간
  ///
  /// 에뮬레이터 권한 응답이 빨라도 화면 전환이 튀지 않도록 유지
  static const Duration _minimumCheckingDuration = Duration(milliseconds: 850);

  /// 확인 중 UI가 먼저 그려지도록 짧게 대기
  static const Duration _checkingPaintDelay = Duration(milliseconds: 180);

  bool get _isDeniedMode => widget.mode == CameraPermissionViewMode.denied;

  String get _initialGuide {
    return _isDeniedMode
        ? TtsScriptProvider.cameraPermissionDenied
        : TtsScriptProvider.cameraPermissionRequired;
  }

  String get _buttonText {
    if (_isChecking) return '확인 중...';
    return _isDeniedMode ? '다시확인' : '확인';
  }

  String get _bodyText {
    if (_isDeniedMode) {
      return '카메라 권한을 확인할 수 없습니다.\n설정에서 권한을 허용한 뒤 다시확인해주세요.';
    }

    return '점자 학습을 위해 카메라 접근 권한이 필요합니다.\n아래 확인 버튼을 눌러 권한을 확인해주세요.';
  }

  @override
  void initState() {
    super.initState();

    /// 화면 렌더링 후 최초 1회 안내
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speakInitialGuide());
    });
  }

  @override
  void didUpdateWidget(covariant CameraPermissionView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mode == widget.mode) return;

    /// 같은 위젯 재사용 시 새 상태 안내 다시 읽기
    _hasSpokenInitialGuide = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speakInitialGuide());
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
    await _tts.speak(_initialGuide);
  }

  Future<void> _confirmPermission() async {
    if (_isChecking) return;

    final startedAt = DateTime.now();

    setState(() => _isChecking = true);

    /// 확인 중 UI 먼저 노출
    await Future<void>.delayed(_checkingPaintDelay);
    if (!mounted) return;

    if (_isDeniedMode) {
      await _tts.speak(TtsScriptProvider.cameraPermissionRetry);
    } else {
      await _tts.speak(TtsScriptProvider.cameraPermissionChecking);
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumCheckingDuration - elapsed;

    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) return;

    await widget.onConfirm();

    if (!mounted) return;

    setState(() => _isChecking = false);
  }

  Future<void> _openSettings() async {
    await PermissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                    Text(
                      _bodyText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking ? null : _confirmPermission,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _isDeniedMode
                                    ? Icons.refresh
                                    : Icons.check_circle_outline,
                              ),
                        label: Text(
                          _buttonText,
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
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isChecking ? null : _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text(
                          '설정으로 이동',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      child: TextButton.icon(
                        onPressed: _isChecking ? null : widget.onHome,
                        icon: const Icon(Icons.home_outlined),
                        label: const Text(
                          '홈으로 돌아가기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
