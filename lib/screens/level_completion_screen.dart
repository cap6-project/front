import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'level_detail_screen.dart';

class LevelCompletionScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String nextLevelId;
  final String nextLevelName;

  const LevelCompletionScreen({
    super.key,
    this.levelId = 'ENT_001',
    this.levelName = '입문 1',
    this.nextLevelId = 'BAS_001',
    this.nextLevelName = '초급',
  });

  @override
  State<LevelCompletionScreen> createState() => _LevelCompletionScreenState();
}

class _LevelCompletionScreenState extends State<LevelCompletionScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _markLevelCompleted();
    _speakCompletionMessage();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _markLevelCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('done_${widget.levelId}', true);
  }

  Future<void> _speakCompletionMessage() async {
    const message = '학습을 완료했습니다. 수고하셨습니다.';
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(message);
    } catch (_) {
      // ignore
    }
    await Future.delayed(const Duration(milliseconds: 2400));
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _retryLearning() {
    Navigator.pop(context);
  }

  void _goNextLearning() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelDetailScreen(
          levelId: widget.nextLevelId,
          stageTitle: widget.nextLevelName,
          stageDescription: '${widget.nextLevelName} 단계를 시작합니다.',
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 120,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00AEEF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: '뒤로가기',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.maybePop(context),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.arrow_back_ios_new, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '학습 완료',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 14)),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 60, color: Color(0xFF00AEEF)),
                    const SizedBox(height: 18),
                    Text(
                      '학습을 완료했습니다',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.levelName}을(를) 성공적으로 마쳤습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    if (_isSpeaking)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.volume_up, color: Color(0xFF00AEEF)),
                          SizedBox(width: 10),
                          Text('음성 안내 중...', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: _speakCompletionMessage,
                        icon: const Icon(Icons.replay, color: Color(0xFF00AEEF)),
                        label: const Text('다시 듣기', style: TextStyle(color: Color(0xFF00AEEF))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildActionButton('다음 학습으로 넘어가기', _goNextLearning)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildActionButton('학습 다시하기', _retryLearning)),
                ],
              ),
              const SizedBox(height: 16),
              _buildActionButton('홈으로 가기', _goHome),
            ],
          ),
        ),
      ),
    );
  }
}
