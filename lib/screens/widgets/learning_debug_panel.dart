import 'package:flutter/material.dart';

class LearningDebugPanel extends StatelessWidget {
  final VoidCallback onCorrect;
  final VoidCallback onWrong;
  final VoidCallback onCaptureFailed;

  const LearningDebugPanel({
    super.key,
    required this.onCorrect,
    required this.onWrong,
    required this.onCaptureFailed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFACC15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                color: Color(0xFFA16207),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '테스트 더미',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFA16207),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '카메라/AI 연결 전 임시 테스트 영역입니다.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF854D0E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DebugButton(
                label: '정답 처리',
                icon: Icons.check_circle_outline,
                onPressed: onCorrect,
              ),
              _DebugButton(
                label: '오답 처리',
                icon: Icons.error_outline,
                onPressed: onWrong,
              ),
              _DebugButton(
                label: '촬영 실패',
                icon: Icons.camera_alt_outlined,
                onPressed: onCaptureFailed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF854D0E),
        side: const BorderSide(
          color: Color(0xFFFACC15),
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}