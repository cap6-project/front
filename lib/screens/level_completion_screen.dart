import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/screens/active_learning_screen.dart';
import 'package:puzzle_dot/services/learning_navigation_service.dart';
import 'package:puzzle_dot/services/streak_service.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts/tts_script_provider.dart';
import 'package:puzzle_dot/services/xp_service.dart';

class LevelCompletionScreen extends StatefulWidget {
  final String levelId;
  final String levelName;
  final String itemName;
  final List<CurriculumItem>? allItems;
  final int? currentIndex;
  final int xpEarned;

  const LevelCompletionScreen({
    super.key,
    this.levelId = '',
    this.levelName = '',
    this.itemName = '',
    this.allItems,
    this.currentIndex,
    this.xpEarned = XpService.xpPerItem,
  });

  @override
  State<LevelCompletionScreen> createState() => _LevelCompletionScreenState();
}

class _LevelCompletionScreenState extends State<LevelCompletionScreen> {
  final AppTtsService _tts = AppTtsService();

  bool _isSpeaking = false;
  int _streak = 0;
  int _totalXp = 0;

  bool get _hasNext {
    return LearningNavigationService.hasNext(
      items: widget.allItems,
      currentIndex: widget.currentIndex,
    );
  }

  CurriculumItem? get _currentItem {
    return LearningNavigationService.getCurrentItem(
      items: widget.allItems,
      currentIndex: widget.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();

    /// 완료 화면 진입 후 통계 로드와 TTS 실행
    ///
    /// 이전 학습 화면에서 말하지 않음
    /// 화면 전환 중 TTS 끊김 방지
    unawaited(_loadStatsAndSpeak());
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _loadStatsAndSpeak() async {
    final streak = await StreakService.getStreak();
    final totalXp = await XpService.getTotalXp();

    if (!mounted) return;

    setState(() {
      _streak = streak;
      _totalXp = totalXp;
    });

    await _speak();
  }

  Future<void> _speak() async {
    if (_isSpeaking) return;

    setState(() => _isSpeaking = true);

    final message = TtsScriptProvider.completion(
      itemName: widget.itemName,
      xpEarned: widget.xpEarned,
    );

    await _tts.speak(message);

    if (!mounted) return;

    setState(() => _isSpeaking = false);
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    if (!mounted) return;

    setState(() => _isSpeaking = false);
  }

  Future<void> _goHome() async {
    await _stopSpeaking();

    if (!mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _goNext() async {
    await _stopSpeaking();

    final nextItem = LearningNavigationService.getNextItem(
      items: widget.allItems,
      currentIndex: widget.currentIndex,
    );

    final nextIndex = LearningNavigationService.getNextIndex(
      items: widget.allItems,
      currentIndex: widget.currentIndex,
    );

    final allItems = widget.allItems;

    if (nextItem == null || nextIndex == null || allItems == null) {
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveLearningScreen(
          item: nextItem,
          levelId: widget.levelId,
          levelName: widget.levelName,
          allItems: allItems,
          currentIndex: nextIndex,
        ),
      ),
    );
  }

  Future<void> _retryCurrentItem() async {
    await _stopSpeaking();

    final currentItem = _currentItem;
    final currentIndex = widget.currentIndex;
    final allItems = widget.allItems;

    if (currentItem == null || currentIndex == null || allItems == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveLearningScreen(
          item: currentItem,
          levelId: widget.levelId,
          levelName: widget.levelName,
          allItems: allItems,
          currentIndex: currentIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (_, __) {
        unawaited(_tts.stop());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F6FF),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompletionTopBar(
                  onRetry: _retryCurrentItem,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CompletionCard(
                          itemName: widget.itemName,
                          isSpeaking: _isSpeaking,
                          onReplay: _speak,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Daily Streak',
                                value: '$_streak Days',
                                caption: '연속 학습일',
                                icon: Icons.local_fire_department,
                                iconColor: const Color(0xFFF97316),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'XP Earned',
                                value: '+${widget.xpEarned} XP',
                                caption: '누적 $_totalXp XP',
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _CompletionActions(
                  hasNext: _hasNext,
                  onHome: _goHome,
                  onNext: _goNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionTopBar extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _CompletionTopBar({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: '현재 문제 다시하기',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => unawaited(onRetry()),
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
              Icons.refresh,
              size: 22,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  final String itemName;
  final bool isSpeaking;
  final Future<void> Function() onReplay;

  const _CompletionCard({
    required this.itemName,
    required this.isSpeaking,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final spokenItemName = TtsScriptProvider.spokenItemName(itemName);

    return Container(
      padding: const EdgeInsets.all(28),
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
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x3322C55E),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '정답입니다!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF15803D),
            ),
          ),
          if (itemName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '완료한 학습: $spokenItemName',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isSpeaking)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.volume_up,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '음성 안내 중...',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => unawaited(onReplay()),
              icon: const Icon(
                Icons.replay,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              label: const Text(
                '다시 듣기',
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompletionActions extends StatelessWidget {
  final bool hasNext;
  final Future<void> Function() onHome;
  final Future<void> Function() onNext;

  const _CompletionActions({
    required this.hasNext,
    required this.onHome,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineButton(
            label: '홈으로',
            onPressed: () => unawaited(onHome()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _GradientButton(
            label: hasNext ? '다음단계' : '다음 단계 없음',
            onPressed: hasNext ? () => unawaited(onNext()) : null,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value, $caption',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF22C55E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x22006CC3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: enabled ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 58,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.white,
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}