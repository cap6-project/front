import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'level_detail_screen.dart';

class LevelCompletionScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String nextLevelId;
  final String nextLevelName;
  final double completionRate;

  const LevelCompletionScreen({
    super.key,
    this.levelId = 'ENT_001',
    this.levelName = '입문 1',
    this.nextLevelId = 'BAS_001',
    this.nextLevelName = '초급',
    this.completionRate = 0.92,
  });

  @override
  State<LevelCompletionScreen> createState() => _LevelCompletionScreenState();
}

class _LevelCompletionScreenState extends State<LevelCompletionScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  final FocusNode _replayFocus = FocusNode();
  final FocusNode _nextButtonFocus = FocusNode();
  final FocusNode _retryButtonFocus = FocusNode();
  final FocusNode _homeButtonFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    TtsManager.instance.register(_tts);
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
    final isReviewRecommended = widget.completionRate < 0.8;
    final levelMessage = '${widget.levelName} 단계 학습을 완료했습니다.';
    final message = isReviewRecommended
        ? '$levelMessage 정확도가 낮아 복습을 추천합니다. 학습 다시하기 버튼을 누르면 복습을 시작할 수 있습니다.'
        : '$levelMessage 다음 학습으로 이어가기를 추천합니다. 다음 학습 버튼을 누르면 다음 단계를 시작합니다.';

    setState(() => _isSpeaking = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_replayFocus);
      }
    });

    try {
      await _tts.speak(message);
    } catch (_) {
      // ignore
    }

    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() => _isSpeaking = false);
      _focusRecommendedAction();
    }
  }

  void _focusRecommendedAction() {
    if (!mounted) return;
    final focusNode = widget.completionRate < 0.8
        ? _retryButtonFocus
        : _nextButtonFocus;
    FocusScope.of(context).requestFocus(focusNode);
  }

  Future<void> _stopTts() async {
    try {
      _tts.stop(); // Remove await for faster response
    } catch (_) {
      // ignore
    }
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _goHome() async {
    await _stopTts();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _retryLearning() async {
    await _stopTts();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelDetailScreen(
          levelId: widget.levelId,
          stageTitle: widget.levelName,
          stageDescription: '${widget.levelName} 단계를 다시 시작합니다.',
        ),
      ),
    );
  }

  Future<void> _goNextLearning() async {
    await _stopTts();
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

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required Gradient gradient,
    Color textColor = Colors.white,
    double height = 58,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22006CC3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            focusNode: focusNode,
            autofocus: autofocus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
    Color borderColor = const Color(0xFF2563EB),
    Color textColor = const Color(0xFF2563EB),
    double height = 58,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: height,
        child: OutlinedButton(
          focusNode: focusNode,
          autofocus: autofocus,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor, width: 1.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white,
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    TtsManager.instance.unregister(_tts);
    _tts.stop();
    _replayFocus.dispose();
    _nextButtonFocus.dispose();
    _retryButtonFocus.dispose();
    _homeButtonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReviewRecommended = widget.completionRate < 0.8;
    final recommendationTitle = isReviewRecommended
        ? '복습을 추천해요'
        : '다음 학습을 추천해요';
    final recommendationText = isReviewRecommended
        ? '정확도가 낮습니다. 학습 다시하기로 복습을 시작해 보세요.'
        : '잘했어요! 다음 학습으로 이어가기를 추천합니다.';

    return WillPopScope(
      onWillPop: () async {
        await _stopTts();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F4FF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                        onTap: () async {
                          await _stopTts();
                          Navigator.maybePop(context);
                        },
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
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Level Cleared',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 32,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 98,
                        height: 98,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF38BDF8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2200A3FF),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Level Cleared',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${widget.levelName}을(를) 성공적으로 마쳤습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sync,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Syncing Progress...',
                                    style: TextStyle(
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '85% Complete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: LinearProgressIndicator(
                          value: 0.85,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFE0F2FE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recommendationTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recommendationText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isSpeaking)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.volume_up, color: Color(0xFF2563EB)),
                            SizedBox(width: 10),
                            Text(
                              '음성 안내 중...',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          focusNode: _replayFocus,
                          onPressed: _speakCompletionMessage,
                          icon: const Icon(
                            Icons.replay,
                            color: Color(0xFF2563EB),
                          ),
                          label: const Text(
                            '다시 듣기',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _buildOutlineButton(
                        label: '학습 다시하기',
                        onPressed: _retryLearning,
                        focusNode: _retryButtonFocus,
                        borderColor: const Color(0xFF2563EB),
                        textColor: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildGradientButton(
                        label: '다음 학습',
                        onPressed: _goNextLearning,
                        focusNode: _nextButtonFocus,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildOutlineButton(
                  label: '홈으로 가기',
                  onPressed: _goHome,
                  focusNode: _homeButtonFocus,
                  borderColor: const Color(0xFF2563EB),
                  textColor: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
