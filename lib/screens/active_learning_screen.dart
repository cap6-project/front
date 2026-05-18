import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puzzle_dot/controllers/active_learning_controller.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/screens/level_completion_screen.dart';
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

  int get _completedCount => widget.currentIndex;
  int get _totalCount => widget.allItems.length;

  @override
  void initState() {
    super.initState();

    _controller = ActiveLearningController(targetItem: widget.item);
    _controller.addListener(_handleControllerChanged);

    /// 화면 진입 안내 TTS
    ///
    /// 문장은 TtsScriptProvider에서 관리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speakCurrentGuide());
    });
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

    await _tts.speak(TtsScriptProvider.analyzing);

    final result = await _controller.analyzeImage(picked.path);
    if (!mounted) return;

    await _handleLearningResult(result);
  }

  Future<void> _handleLearningResult(LearningResult result) async {
    if (result.isCorrect) {
      _goCompletion();
      return;
    }

    final title = result.isIncomplete ? '다시 확인해 주세요' : '다시 시도해 보세요';

    final message = result.hint.isEmpty
        ? '점자 모양을 다시 확인해주세요.'
        : TtsScriptProvider.normalizeForSpeech(result.hint);

    _showResultDialog(
      title: title,
      message: message,
    );

    unawaited(_tts.speak(message));
  }

  void _goCompletion() {
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
          Semantics(
            button: true,
            label: '다시 듣기',
            child: IconButton(
              onPressed: () => unawaited(_speakCurrentGuide()),
              icon: const Icon(Icons.volume_up_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LearningProgressHeader(
                currentIndex: widget.currentIndex,
                totalCount: widget.allItems.length,
              ),
              const SizedBox(height: 18),
              _LearningGoalCard(item: widget.item),
              const SizedBox(height: 20),
              const _LearningInstructionCard(),
              const SizedBox(height: 28),
              _AnalyzeButton(
                isAnalyzing: isAnalyzing,
                onPressed: _pickImageAndAnalyze,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 18),
                _LearningDebugPanel(
                  onCorrect: () => _applyDebugResult(
                    LearningResult.correct(),
                  ),
                  onIncorrect: () => _applyDebugResult(
                    LearningResult.incorrect(
                      TtsScriptProvider.incorrectHint(widget.item),
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

class _LearningProgressHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const _LearningProgressHeader({
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final current = currentIndex + 1;

    return Semantics(
      label: '학습 진행률 $current / $totalCount',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: totalCount == 0 ? 0 : currentIndex / totalCount,
                minHeight: 10,
                color: const Color(0xFF00AEEF),
                backgroundColor: const Color(0xFFDCEBFA),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$currentIndex/$totalCount 완료',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningGoalCard extends StatelessWidget {
  final CurriculumItem item;

  const _LearningGoalCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.character} 학습 목표',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              '학습 목표',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF1D6FA8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.character,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningInstructionCard extends StatelessWidget {
  const _LearningInstructionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF1D6FA8),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '점자판에 위 문자를 만든 후 이미지를 업로드하세요.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1D4ED8),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final bool isAnalyzing;
  final Future<void> Function() onPressed;

  const _AnalyzeButton({
    required this.isAnalyzing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isAnalyzing ? null : onPressed,
        icon: isAnalyzing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF1D4ED8),
                ),
              )
            : const Icon(Icons.image_outlined),
        label: Text(
          isAnalyzing ? '분석 중...' : '테스트 이미지 업로드',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1D4ED8),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF1D4ED8),
          side: const BorderSide(
            color: Color(0xFFBFD7F7),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _LearningDebugPanel extends StatelessWidget {
  final Future<void> Function() onCorrect;
  final Future<void> Function() onIncorrect;
  final Future<void> Function() onIncomplete;

  const _LearningDebugPanel({
    required this.onCorrect,
    required this.onIncorrect,
    required this.onIncomplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '개발 테스트',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DebugButton(
                label: '정답',
                onPressed: onCorrect,
              ),
              _DebugButton(
                label: '오답',
                onPressed: onIncorrect,
              ),
              _DebugButton(
                label: '미완료',
                onPressed: onIncomplete,
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
  final Future<void> Function() onPressed;

  const _DebugButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => unawaited(onPressed()),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF92400E),
        side: const BorderSide(
          color: Color(0xFFF59E0B),
        ),
      ),
      child: Text(label),
    );
  }
}