import 'package:flutter/material.dart';
import 'package:puzzle_dot/data/curriculum_data.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/services/progress_service.dart';
import 'package:puzzle_dot/screens/active_learning_screen.dart';

class CurriculumSelectionScreen extends StatefulWidget {
  final String levelId;
  final String levelTitle;

  const CurriculumSelectionScreen({
    super.key,
    required this.levelId,
    required this.levelTitle,
  });

  @override
  State<CurriculumSelectionScreen> createState() =>
      _CurriculumSelectionScreenState();
}

class _CurriculumSelectionScreenState
    extends State<CurriculumSelectionScreen> {
  Set<String> _completedIds = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final items = curriculumData[widget.levelId] ?? [];
    final completed = await ProgressService.getCompletedIds(items);
    if (mounted) setState(() => _completedIds = completed);
  }

  @override
  Widget build(BuildContext context) {
    final items = curriculumData[widget.levelId] ?? [];
    final ratio =
        items.isEmpty ? 0.0 : _completedIds.length / items.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.levelTitle),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Text(
                  '${_completedIds.length}/${items.length} 완료',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      color: const Color(0xFF00AEEF),
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(ratio * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _CurriculumCard(
                  item: item,
                  isCompleted: _completedIds.contains(item.id),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveLearningScreen(
                        item: item,
                        levelId: widget.levelId,
                        levelName: widget.levelTitle,
                        allItems: items,       // ← 전체 목록 전달
                        currentIndex: index,   // ← 현재 인덱스 전달
                      ),
                    ),
                  ).then((_) => _loadProgress()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurriculumCard extends StatelessWidget {
  final CurriculumItem item;
  final bool isCompleted;
  final VoidCallback onTap;

  const _CurriculumCard(
      {required this.item,
      required this.isCompleted,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 6))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    item.character,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isCompleted
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.character,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(item.description,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                size: 18,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}