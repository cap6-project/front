import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/models/learning_result.dart';
import 'package:puzzle_dot/services/learning/hint_service.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';

/// 틀린 셀 안내 화면
///
/// 역할:
/// - AI가 반환한 틀린 셀 인덱스를 사용자에게 표시
/// - 오답 힌트 TTS 실행
/// - 다시 시도 흐름으로 학습 화면 복귀
class WrongCellHintScreen extends StatefulWidget {
  final CurriculumItem item;
  final LearningResult result;

  const WrongCellHintScreen({
    super.key,
    required this.item,
    required this.result,
  });

  @override
  State<WrongCellHintScreen> createState() => _WrongCellHintScreenState();
}

class _WrongCellHintScreenState extends State<WrongCellHintScreen> {
  final AppTtsService _tts = AppTtsService();
  final HintService _hintService = const HintService();

  String get _cellText {
    return _hintService.cellIndexListText(widget.result.wrongCellIndexes);
  }

  String get _hintText {
    final hint = widget.result.hint.trim();
    if (hint.isNotEmpty) return hint;

    return _hintService.incorrectHint(widget.item);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_speakHint());
    });
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _speakHint() async {
    final message = TtsScriptProvider.normalizeForSpeech(
      '오답입니다. $_cellText을 확인해주세요. $_hintText',
    );

    await _tts.speak(message);
  }

  void _goBackToLearning() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: const Text('틀린 셀 안내'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => unawaited(_speakHint()),
            icon: const Icon(Icons.volume_up_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: '오답 안내',
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 56,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        '다시 확인해 주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hintText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '틀린 셀',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _cellText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '해당 셀의 점 위치를 다시 확인한 뒤 재촬영해주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _goBackToLearning,
                  icon: const Icon(Icons.refresh),
                  label: const Text(
                    '다시 시도하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
