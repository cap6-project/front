import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 학습 이미지 분석 버튼
///
/// 역할:
/// - 분석 시작 버튼 표시
/// - 분석 중 로딩 상태 표시
///
/// 이미지 선택/분석 로직은 화면/controller가 담당
class AnalyzeButton extends StatefulWidget {
  final bool isAnalyzing;
  final Future<void> Function() onPressed;
  final IconData icon;
  final String label;

  const AnalyzeButton({
    super.key,
    required this.isAnalyzing,
    required this.onPressed,
    this.icon = Icons.image_outlined,
    this.label = '테스트 이미지 업로드',
  });

  @override
  State<AnalyzeButton> createState() => _AnalyzeButtonState();
}

class _AnalyzeButtonState extends State<AnalyzeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: widget.isAnalyzing ? null : widget.onPressed,
        icon: widget.isAnalyzing
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                ),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    backgroundColor:
                        const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                    color: const Color(0xFF1D4ED8),
                    value: 0.75,
                  ),
                ),
              )
            : Icon(widget.icon),
        label: Text(
          widget.isAnalyzing ? '분석 중...' : widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D4ED8),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF1D4ED8),
          side: const BorderSide(color: Color(0xFFBFD7F7), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
