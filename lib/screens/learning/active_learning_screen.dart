import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puzzle_dot/controllers/active_learning_controller.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_capture_source.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/screens/completion/level_completion_screen.dart';
import 'package:puzzle_dot/screens/learning/widgets/analyze_button.dart';
import 'package:puzzle_dot/screens/learning/widgets/learning_debug_panel.dart';
import 'package:puzzle_dot/screens/learning/widgets/learning_goal_card.dart';
import 'package:puzzle_dot/screens/learning/widgets/learning_instruction_card.dart';
import 'package:puzzle_dot/screens/learning/widgets/learning_progress_header.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

class ActiveLearningScreen extends StatefulWidget {
  final CurriculumItem item;
  final String levelId;
  final String levelName;
  final List<CurriculumItem> allItems;
  final int currentIndex;

  const ActiveLearningScreen({
    super.key,
    required this.item,
    required this.levelId,
    required this.levelName,
    required this.allItems,
    required this.currentIndex,
  });

  @override
  State<ActiveLearningScreen> createState() => _ActiveLearningScreenState();
}

class _ActiveLearningScreenState extends State<ActiveLearningScreen> {
  late final ActiveLearningController _controller;
  final AppTtsService _tts = AppTtsService();
  bool _isLeavingScreen = false;

  int get _completedCount => widget.currentIndex;
  int get _totalCount => widget.allItems.length;

  @override
  void initState() {
    super.initState();

    _controller = ActiveLearningController(targetItem: widget.item);
    _controller.addListener(_handleControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speakCurrentGuide());
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();

    /// 화면 이동 중 dispose에서는 stop 호출 방지
    if (!_isLeavingScreen) {
      unawaited(_tts.stop());
    }

    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _speakCurrentGuide() async {
    final guide = TtsScriptProvider.learningGuide(widget.item);
    final progress = TtsScriptProvider.progressSummary(
      completedCount: _completedCount,
      totalCount: _totalCount,
    );

    await _tts.speak('$progress $guide');
  }

  Future<void> _pickImageAndAnalyze() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final source = LearningCaptureSource.galleryMock(picked.path);
    await _analyzeCapture(source);
  }

  /// 학습 분석 공통 진입점
  ///
  /// 갤러리 mock 이미지와 실제 카메라 촬영 이미지 모두 이 함수로 연결
  Future<void> _analyzeCapture(LearningCaptureSource source) async {
    await _tts.speak(TtsScriptProvider.analyzing);

    final result = await _controller.analyzeCapture(source);
    if (!mounted) return;

    await _handleLearningResult(result);
  }

  Future<void> _handleLearningResult(LearningResult result) async {
    if (result.isCorrect) {
      _goCompletion();
      return;
    }

    final title = result.isIncomplete ? '다시 확인해 주세요' : '다시 시도해 보세요';

    /// Alert 표시용 문장
    ///
    /// 화면에는 원문 reading 유지
    /// TTS 발음 치환은 speak 직전에만 적용
    final displayMessage =
        result.hint.isEmpty ? '점자 모양을 다시 확인해주세요.' : result.hint;

    final ttsMessage = TtsScriptProvider.normalizeForSpeech(displayMessage);

    _showResultDialog(
      title: title,
      message: displayMessage,
    );

    unawaited(_tts.speak(ttsMessage));
  }

  void _goCompletion() {
    _isLeavingScreen = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LevelCompletionScreen(
          levelId: widget.levelId,
          levelName: widget.levelName,
          itemName: widget.item.character,
          allItems: widget.allItems,
          currentIndex: widget.currentIndex,
        ),
      ),
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDebugResult(LearningResult result) async {
    final applied = await _controller.applyDebugResult(result);
    if (!mounted) return;

    await _handleLearningResult(applied);
  }

  /// 오답 Alert 표시용 문장
  ///
  /// 화면에는 원래 reading 표시
  /// TTS 발음 치환은 speak 직전에만 적용
  String _incorrectDisplayHint(CurriculumItem item) {
    final reading = item.reading.trim();
    final character = item.character.trim();
    final label = reading.isNotEmpty ? reading : character;

    return '$label 점형을 다시 확인해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final isAnalyzing = _controller.isAnalyzing;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(widget.levelName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => unawaited(_speakCurrentGuide()),
            icon: const Icon(Icons.volume_up_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LearningProgressHeader(
                currentIndex: widget.currentIndex,
                totalCount: widget.allItems.length,
              ),
              const SizedBox(height: 18),
              LearningGoalCard(item: widget.item),
              const SizedBox(height: 20),
              const LearningInstructionCard(),
              const SizedBox(height: 28),
              AnalyzeButton(
                isAnalyzing: isAnalyzing,
                onPressed: _pickImageAndAnalyze,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 18),
                LearningDebugPanel(
                  onCorrect: () => _applyDebugResult(
                    LearningResult.correct(),
                  ),
                  onIncorrect: () => _applyDebugResult(
                    LearningResult.incorrect(
                      _incorrectDisplayHint(widget.item),
                    ),
                  ),
                  onIncomplete: () => _applyDebugResult(
                    LearningResult.incomplete(
                      TtsScriptProvider.incompleteHint(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}