import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'home_screen.dart';
import 'level_detail_screen.dart';

class LearningCompleteScreen extends StatefulWidget {
  final String? levelName;
  final String? nextLevelName;
  final bool isSuccess;
  final String levelId;

  const LearningCompleteScreen({
    super.key,
    this.levelName,
    this.nextLevelName,
    this.isSuccess = true,
    this.levelId = '',
  });

  @override
  State<LearningCompleteScreen> createState() => _LearningCompleteScreenState();
}

class _LearningCompleteScreenState extends State<LearningCompleteScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    TtsManager.instance.register(_tts);
    _initializeTts();
    _speakCompletionMessage();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.8);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _speakCompletionMessage() async {
    const message = '학습을 완료했습니다';
    setState(() => _isSpeaking = true);

    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS Error: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
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

  Future<void> _handleRetry() async {
    await _stopTts();
    Navigator.pop(context);
  }

  Future<void> _handleHome() async {
    await _stopTts();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _handleNextLevel() async {
    final nextLevel = widget.nextLevelName ?? '초급';
    String nextLevelId;
    switch (nextLevel) {
      case '입문':
        nextLevelId = '1';
        break;
      case '초급':
        nextLevelId = '2';
        break;
      case '중급':
        nextLevelId = '3';
        break;
      case '고급':
        nextLevelId = '4';
        break;
      default:
        nextLevelId = '2';
    }
    await _stopTts();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LevelDetailScreen(
          levelId: nextLevelId,
          stageTitle: nextLevel,
          stageDescription: '$nextLevel 단계를 시작합니다',
        ),
      ),
      (route) => false,
    );
  }

  void _handleReplayTts() {
    _speakCompletionMessage();
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
      onWillPop: () async {
        await _stopTts();
        return true;
      },
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final isLargeScreen = MediaQuery.of(context).size.height > 800;
          final buttonHeight = isLargeScreen ? 120.0 : 100.0;
          final buttonSpacing = isLargeScreen ? 24.0 : 16.0;
          final titleFontSize = isLargeScreen ? 56.0 : 48.0;

          Widget buildActionButton(String label, VoidCallback onPressed) {
            return SizedBox(
              height: buttonHeight,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 36 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: colorScheme.background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                            child: const SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(Icons.arrow_back_ios_new, size: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            '학습 완료',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.onBackground.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '학습을 완료했습니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '최고예요! 다음 단계로 넘어가거나 다시 복습할 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurface.withOpacity(0.78),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isSpeaking)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.volume_up,
                                  color: colorScheme.secondary,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '음성 재생 중...',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.secondary,
                              ),
                              onPressed: _handleReplayTts,
                              icon: const Icon(Icons.replay),
                              label: const Text('다시 듣기'),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: buttonSpacing * 2),
                    buildActionButton('다시하기', _handleRetry),
                    SizedBox(height: buttonSpacing),
                    buildActionButton('홈으로', _handleHome),
                    SizedBox(height: buttonSpacing),
                    buildActionButton('다음학습', _handleNextLevel),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
