import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_dot/controllers/practice_controller.dart';
import 'package:puzzle_dot/screens/permission_screen.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller;
  final AppTtsService _tts = AppTtsService();

  PracticeCameraStatus? _lastSpokenStatus;

  @override
  void initState() {
    super.initState();

    _controller = PracticeController();
    _controller.addListener(_handleControllerChanged);

    /// Practice 탭이 실제 선택된 뒤 권한 확인 시작
    ///
    /// HomeScreen에서 lazy 생성하므로 앱 시작 시점에는 실행되지 않음
    unawaited(_controller.prepare());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;

    setState(() {});

    /// 권한 안내 TTS는 CameraPermissionView에서만 실행
    ///
    /// ready/unavailable 상태 안내만 Practice 화면에서 담당
    final status = _controller.status;
    if (_lastSpokenStatus == status) return;

    _lastSpokenStatus = status;

    switch (status) {
      case PracticeCameraStatus.ready:
        unawaited(_tts.speak(TtsScriptProvider.cameraReady));
        break;

      case PracticeCameraStatus.unavailable:
        unawaited(_tts.speak(TtsScriptProvider.cameraUnavailable));
        break;

      case PracticeCameraStatus.checking:
      case PracticeCameraStatus.permissionDenied:
        break;
    }
  }

  Future<void> _retryCameraSetup() async {
    _lastSpokenStatus = null;
    await _controller.prepare();
  }

  Future<void> _capture() async {
    await _tts.speak(TtsScriptProvider.capturing);

    final imagePath = await _controller.capture();
    if (!mounted) return;

    if (imagePath == null) {
      await _tts.speak(TtsScriptProvider.captureFailed);
      return;
    }

    await _tts.speak(TtsScriptProvider.analyzing);

    /// TODO: AI/OpenCV 분석 서비스 연결 지점
    ///
    /// imagePath를 분석 서비스에 전달
    /// 분석 결과를 ActiveLearning 또는 HintService 흐름과 연결
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('촬영 이미지를 준비했습니다. 분석 로직은 다음 단계에서 연결합니다.'),
      ),
    );
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_controller.status) {
      case PracticeCameraStatus.checking:
        return const _PracticeLoadingView();

      case PracticeCameraStatus.permissionDenied:
        return CameraPermissionView(
          onRetry: _retryCameraSetup,
          onHome: _goHome,
        );

      case PracticeCameraStatus.unavailable:
        return _CameraUnavailableView(
          onRetry: _retryCameraSetup,
          onHome: _goHome,
        );

      case PracticeCameraStatus.ready:
        return _PracticeCameraView(
          cameraController: _controller.cameraController,
          isCapturing: _controller.isCapturing,
          onCapture: _capture,
        );
    }
  }
}

class _PracticeLoadingView extends StatelessWidget {
  const _PracticeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('practice_loading'),
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Semantics(
          label: '카메라 준비 중',
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text(
                '카메라를 준비하고 있습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailableView extends StatelessWidget {
  final Future<void> Function() onRetry;
  final VoidCallback onHome;

  const _CameraUnavailableView({
    required this.onRetry,
    required this.onHome,
  });

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
              const Text(
                '카메라를 사용할 수 없습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '에뮬레이터 또는 현재 기기에서 카메라를 찾을 수 없습니다.\n실제 기기에서 다시 확인해주세요.',
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
                label: '다시 확인, 버튼',
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
                label: '홈으로 돌아가기, 버튼',
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

class _PracticeCameraView extends StatelessWidget {
  final CameraController? cameraController;
  final bool isCapturing;
  final Future<void> Function() onCapture;

  const _PracticeCameraView({
    required this.cameraController,
    required this.isCapturing,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final controller = cameraController;

    return Container(
      key: const ValueKey('practice_camera'),
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                '카메라 학습',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                '점자판을 화면 중앙에 맞춘 뒤 촬영해주세요',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8B949E),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    color: const Color(0xFF161B22),
                    child: controller == null
                        ? const _CameraPreviewFallback()
                        : CameraPreview(controller),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: isCapturing ? null : onCapture,
                  icon: isCapturing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    isCapturing ? '촬영 중...' : '촬영하기',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AEEF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF1F6FEB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPreviewFallback extends StatelessWidget {
  const _CameraPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Color(0xFF30363D),
          ),
          SizedBox(height: 16),
          Text(
            '카메라 화면을 준비하고 있습니다',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B949E),
            ),
          ),
        ],
      ),
    );
  }
}