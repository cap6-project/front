import 'package:flutter/material.dart';
import 'package:puzzle_dot/services/tts_manager.dart';

import 'package:puzzle_dot/screens/chat_screen.dart';
import 'package:puzzle_dot/screens/level_completion_screen.dart';
import 'package:puzzle_dot/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _learningPaths = [
    {
      'title': 'Intro 1',
      'subtitle': '기본 개념 익히기',
      'progress': 0.85,
      'unlocked': true,
    },
    {
      'title': 'Intro 2',
      'subtitle': '감각 익히기',
      'progress': 0.36,
      'unlocked': true,
    },
    {
      'title': 'Beginner 1',
      'subtitle': '패턴 인식',
      'progress': 0.72,
      'unlocked': true,
    },
    {
      'title': 'Beginner 2',
      'subtitle': '문제 풀이',
      'progress': 0.0,
      'unlocked': false,
    },
    {
      'title': 'Intermediate 1',
      'subtitle': '속도 향상',
      'progress': 0.0,
      'unlocked': false,
    },
    {
      'title': 'Intermediate 2',
      'subtitle': '실전 연습',
      'progress': 0.0,
      'unlocked': false,
    },
    {
      'title': 'Advanced 1',
      'subtitle': '도전 과제',
      'progress': 0.0,
      'unlocked': false,
    },
    {
      'title': 'Advanced 2',
      'subtitle': '완성하기',
      'progress': 0.0,
      'unlocked': false,
    },
  ];

  void _onTapNav(int index) {
    TtsManager.instance.stopAll();
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title 버튼',
      child: Material(
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
                  offset: Offset(0, 12),
                ),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLearningPathCard(Map<String, dynamic> item) {
    final progress = item['progress'] as double;
    final unlocked = item['unlocked'] as bool;

    return Semantics(
      button: unlocked,
      label:
          '${item['title']} ${unlocked ? '진행 ${(progress * 100).round()}% 완료' : '잠금됨'}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
            Text(
              item['subtitle'] as String,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
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
    );
  }

  Widget _buildTopCard() {
    return Container(
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
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(Icons.menu_book, size: 28, color: Color(0xFF1D4ED8)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Curriculum Selection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Master the Braille code through our structured learning paths.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Chatbot',
                    subtitle: 'Ask anything',
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF00AEEF),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    title: 'Settings',
                    subtitle: 'Preferences',
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF6366F1),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LevelCompletionScreen(
                        levelId: 'intro_1',
                        levelName: '입문 1',
                        nextLevelName: '초급',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'View Level Completion',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
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
          _buildTopCard(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Daily Streak',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '5 Days',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'XP Earned',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '+150 XP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Continue where you left off',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (var item in _learningPaths.take(3)) ...[
            _buildLearningPathCard(item),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return ChatScreen(onBackPressed: () => setState(() => _selectedIndex = 0));
  }

  Widget _buildSettingsTab() {
    return SettingsScreen(
      onBackPressed: () => setState(() => _selectedIndex = 0),
      isActive: _selectedIndex == 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Learn'),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chat',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];

    final titles = ['PuzzleDot', 'PuzzleBot', 'Settings'];
    final subtitles = [
      'Learning dashboard',
      'Chat with PuzzleBot',
      'Profile and preferences',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titles[_selectedIndex],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitles[_selectedIndex],
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
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
                        'https://i.pravatar.cc/150?img=12',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeTab(),
                  _buildChatTab(),
                  _buildSettingsTab(),
                ],
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
