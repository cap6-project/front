import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:puzzle_dot/models/curriculum_item.dart';
import 'package:puzzle_dot/services/progress_service.dart';
import 'package:puzzle_dot/screens/level_completion_screen.dart';

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
  State<ActiveLearningScreen> createState() =>
      _ActiveLearningScreenState();
}

class _ActiveLearningScreenState extends State<ActiveLearningScreen> {
  bool _isAnalyzing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _isAnalyzing = true);
    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final isCorrect = DateTime.now().millisecond.isOdd;

    if (isCorrect) {
      await ProgressService.markCompleted(widget.item.id);
      if (!mounted) return;
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
    } else {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showFailureDialog();
    }
  }

  void _showFailureDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('다시 시도해 보세요',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content:
            const Text('점자가 정확하지 않습니다.\n다시 찍어서 업로드해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        title: Text(widget.levelName),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 36, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0E000000),
                        blurRadius: 20,
                        offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      '학습 목표',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Color(0xFF1D6FA8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.character,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF1D6FA8), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '점자판에 위 문자를 만든 후\n갤러리에서 사진을 업로드하세요.',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1D4ED8),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isAnalyzing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('분석 중...',
                        style: TextStyle(color: Color(0xFF64748B))),
                  ],
                )
              else
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('이미지 업로드',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(
                          color: Color(0xFFBFD7F7), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}