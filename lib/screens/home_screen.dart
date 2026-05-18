import 'package:flutter/material.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'package:puzzle_dot/services/progress_service.dart';
import 'package:puzzle_dot/data/curriculum_data.dart';
import 'package:puzzle_dot/screens/chat_screen.dart';
import 'package:puzzle_dot/screens/settings_screen.dart';
import 'package:puzzle_dot/screens/practice_screen.dart';
import 'package:puzzle_dot/screens/curriculum_selection_screen.dart';
import 'package:puzzle_dot/screens/widgets/app_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  // 레벨 정의 (levelId, title, subtitle, group)
  static const _levels = [
    {'id': 'ENT_1', 'title': '입문 1', 'subtitle': '기본 개념 익히기', 'group': 'intro'},
    {'id': 'ENT_2', 'title': '입문 2', 'subtitle': '감각 익히기', 'group': 'intro'},
    {'id': 'BAS_1', 'title': '초급 1', 'subtitle': '패턴 인식', 'group': 'beginner'},
    {'id': 'BAS_2', 'title': '초급 2', 'subtitle': '문제 풀이', 'group': 'beginner'},
    {'id': 'INT_1', 'title': '중급 1', 'subtitle': '속도 향상', 'group': 'intermediate'},
    {'id': 'INT_2', 'title': '중급 2', 'subtitle': '실전 연습', 'group': 'intermediate'},
    {'id': 'ADV_1', 'title': '고급 1', 'subtitle': '도전 과제', 'group': 'advanced'},
    {'id': 'ADV_2', 'title': '고급 2', 'subtitle': '완성하기', 'group': 'advanced'},
  ];

  Map<String, double> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final map = await ProgressService.getLevelProgressMap();
    if (mounted) setState(() => _progressMap = map);
  }

  bool _isUnlocked(String levelId) {
    switch (levelId) {
      case 'ENT_1':
      case 'ENT_2':
        return true;
      case 'BAS_1':
      case 'BAS_2':
        final avg = ((_progressMap['ENT_1'] ?? 0) +
                (_progressMap['ENT_2'] ?? 0)) /
            2;
        return avg >= 0.5;
      case 'INT_1':
      case 'INT_2':
        final avg = ((_progressMap['BAS_1'] ?? 0) +
                (_progressMap['BAS_2'] ?? 0)) /
            2;
        return avg >= 0.5;
      case 'ADV_1':
      case 'ADV_2':
        final avg = ((_progressMap['INT_1'] ?? 0) +
                (_progressMap['INT_2'] ?? 0)) /
            2;
        return avg >= 0.5;
      default:
        return false;
    }
  }

  void _onTapNav(int index) {
    TtsManager.instance.stopAll();
    setState(() => _selectedIndex = index);
  }

  Widget _buildLevelCard(Map<String, String> level) {
    final id = level['id']!;
    final title = level['title']!;
    final subtitle = level['subtitle']!;
    final progress = _progressMap[id] ?? 0.0;
    final unlocked = _isUnlocked(id);

    return Semantics(
      button: unlocked,
      label: '$title ${unlocked ? '진행 ${(progress * 100).round()}% 완료' : '잠금됨'}',
      child: GestureDetector(
        onTap: unlocked
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CurriculumSelectionScreen(
                      levelId: id,
                      levelTitle: title,
                    ),
                  ),
                ).then((_) => _loadProgress())
            : null,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 22,
                  offset: Offset(0, 10))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(
                    unlocked ? Icons.check_circle : Icons.lock,
                    size: 18,
                    color: unlocked
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: unlocked ? progress : 0,
                  minHeight: 10,
                  color: unlocked
                      ? const Color(0xFF00AEEF)
                      : const Color(0xFFD1D5DB),
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unlocked ? '${(progress * 100).round()}% 완료' : '잠금됨',
                    style: TextStyle(
                      fontSize: 12,
                      color: unlocked
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    unlocked ? Icons.arrow_forward_ios : Icons.lock,
                    size: 14,
                    color: unlocked
                        ? const Color(0xFF00AEEF)
                        : const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상단 카드
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFECF4FF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 30,
                    offset: Offset(0, 16))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book,
                          size: 28, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '커리큘럼 선택',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '구조화된 학습 경로로 점자를 마스터하세요.',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          title: '챗봇',
                          subtitle: '무엇이든 물어보세요',
                          icon: Icons.chat_bubble_outline,
                          iconColor: const Color(0xFF00AEEF),
                          onTap: () =>
                              setState(() => _selectedIndex = 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          title: '설정',
                          subtitle: '환경 설정',
                          icon: Icons.settings_outlined,
                          iconColor: const Color(0xFF6366F1),
                          onTap: () =>
                              setState(() => _selectedIndex = 3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          // 통계
          Row(
            children: [
              Expanded(
                child: _StatMiniCard(
                    label: '연속 학습일', value: '5일'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatMiniCard(
                    label: '누적 경험치', value: '+150 XP'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            '이어서 학습하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (var level in _levels.take(3).cast<Map<String, String>>()) ...[
            _buildLevelCard(level),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      NavigationDestination(
          icon: Icon(Icons.school_outlined), label: 'Learn'),
      NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined), label: 'Practice'),
      NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
      NavigationDestination(
          icon: Icon(Icons.settings_outlined), label: 'Settings'),
    ];

    final titles = ['PuzzleDot', '카메라 학습', 'PuzzleBot', '설정'];
    final subtitles = [
      '학습 대시보드',
      '카메라로 점자 연습',
      'PuzzleBot과 대화',
      '프로필 및 설정',
    ];

    final tabs = [
      _buildHomeTab(),
      const PracticeScreen(),
      ChatScreen(onBackPressed: () => setState(() => _selectedIndex = 0)),
      SettingsScreen(
        onBackPressed: () => setState(() => _selectedIndex = 0),
        isActive: _selectedIndex == 3,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 18,
                              offset: Offset(0, 10))
                        ],
                      ),
                      child: const Icon(Icons.menu,
                          color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_selectedIndex],
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitles[_selectedIndex],
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFDBEAFE),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: NavigationBar(
          height: 72,
          backgroundColor: Colors.white,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTapNav,
          destinations: navItems,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 24,
                  offset: Offset(0, 12))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatMiniCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000),
              blurRadius: 22,
              offset: Offset(0, 12))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}