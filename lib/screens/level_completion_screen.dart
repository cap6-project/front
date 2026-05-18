import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'package:puzzle_dot/services/streak_service.dart';
import 'package:puzzle_dot/services/xp_service.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'active_learning_screen.dart';

class LevelCompletionScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String itemName;
  final double completionRate;
  final List<CurriculumItem>? allItems;
  final int? currentIndex;

  const LevelCompletionScreen({
    super.key,
    this.levelId = '',
    this.levelName = '',
    this.itemName = '',
    this.completionRate = 1.0,
    this.allItems,
    this.currentIndex,
  });

  @override
  State<LevelCompletionScreen> createState() =>
      _LevelCompletionScreenState();
}

class _LevelCompletionScreenState
    extends State<LevelCompletionScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  int _streak = 0;
  int _totalXp = 0;

  @override
  void initState() {
    super.initState();
    TtsManager.instance.register(_tts);
    _init();
  }

  Future<void> _init() async {
    await _initTts();
    await _loadStats();
    _speak();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final streak = await StreakService.getStreak();
    final xp = await XpService.getTotalXp();
    if (mounted) setState(() { _streak = streak; _totalXp = xp; });
  }

  Future<void> _speak() async {
    if (mounted) setState(() => _isSpeaking = true);
    try {
      await _tts.speak(
          '정답입니다! ${widget.itemName} 학습을 완료했습니다.');
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _stopTts() async {
    try { _tts.stop(); } catch (_) {}
    if (mounted) setState(() => _isSpeaking = false);
  }

  bool get _hasNext {
    final items = widget.allItems;
    final idx = widget.currentIndex;
    return items != null && idx != null && idx + 1 < items.length;
  }

  void _goNext() async {
    await _stopTts();
    final next = widget.allItems![widget.currentIndex! + 1];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveLearningScreen(
          item: next,
          levelId: widget.levelId,
          levelName: widget.levelName,
          allItems: widget.allItems!,
          currentIndex: widget.currentIndex! + 1,
        ),
      ),
    );
  }

  void _goHome() async {
    await _stopTts();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _retry() async {
    await _stopTts();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    TtsManager.instance.unregister(_tts);
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async { await _stopTts(); return true; },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 뒤로가기
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _retry,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 18,
                            offset: Offset(0, 8))
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 24),
                // 결과 카드
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x16000000),
                          blurRadius: 32,
                          offset: Offset(0, 14))
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x3322C55E),
                                blurRadius: 20,
                                offset: Offset(0, 10))
                          ],
                        ),
                        child: const Icon(Icons.check,
                            size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '정답입니다!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      if (widget.itemName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '목표: ${widget.itemName}',
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF64748B)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_isSpeaking)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volume_up,
                                color: Color(0xFF2563EB), size: 20),
                            SizedBox(width: 8),
                            Text('음성 안내 중...',
                                style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: _speak,
                          icon: const Icon(Icons.replay,
                              color: Color(0xFF2563EB), size: 18),
                          label: const Text('다시 듣기',
                              style:
                                  TextStyle(color: Color(0xFF2563EB))),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Streak + XP
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Daily Streak',
                        value: '$_streak Days',
                        icon: Icons.local_fire_department,
                        iconColor: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'XP Earned',
                        value: '+$_totalXp XP',
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: _OutlineBtn(
                          label: '다시하기', onPressed: _retry),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GradientBtn(
                        label: _hasNext ? '다음 문제' : '홈으로',
                        onPressed: _hasNext ? _goNext : _goHome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _OutlineBtn(label: '홈으로 가기', onPressed: _goHome),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GradientBtn(
      {required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22006CC3),
              blurRadius: 20,
              offset: Offset(0, 10))
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _OutlineBtn(
      {required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
              color: Color(0xFF2563EB), width: 1.8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB))),
      ),
    );
  }
}