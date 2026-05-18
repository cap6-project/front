import 'dart:async';

import 'package:flutter/material.dart';
import 'package:puzzle_dot/screens/chat_screen.dart';
import 'package:puzzle_dot/screens/curriculum_selection_screen.dart';
import 'package:puzzle_dot/screens/practice_screen.dart';
import 'package:puzzle_dot/screens/settings_screen.dart';
import 'package:puzzle_dot/screens/widgets/app_drawer.dart';
import 'package:puzzle_dot/services/progress_service.dart';
import 'package:puzzle_dot/services/streak_service.dart';
import 'package:puzzle_dot/services/tts/app_tts_service.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'package:puzzle_dot/services/xp_service.dart';

/// 메인 탭과 홈 대시보드 화면
///
/// 역할:
/// - 하단 네비게이션 상태 관리
/// - 홈 학습 카드 표시
/// - Practice 탭 lazy 생성
/// - 탭 이동 시 기존 TTS 정리
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _selectedIndex;
  Map<String, double> _progressMap = {};
  int _dailyStreak = 0;
  int _totalXp = 0;

  /// 화면 표시용 레벨 정의
  ///
  /// 입문은 1단계만 사용
  /// 이후 단계는 초급/중급/고급 각각 2단계 구성
  static const List<_LearningLevelInfo> _levels = [
    _LearningLevelInfo(
      id: 'ENT_1',
      title: '입문 1',
      subtitle: '점자의 기본 구조 익히기',
      group: _LevelGroup.intro,
    ),
    _LearningLevelInfo(
      id: 'BAS_1',
      title: '초급 1',
      subtitle: '기본 자음 학습',
      group: _LevelGroup.beginner,
    ),
    _LearningLevelInfo(
      id: 'BAS_2',
      title: '초급 2',
      subtitle: '기본 모음 학습',
      group: _LevelGroup.beginner,
    ),
    _LearningLevelInfo(
      id: 'INT_1',
      title: '중급 1',
      subtitle: '된소리와 복합 모음 학습',
      group: _LevelGroup.intermediate,
    ),
    _LearningLevelInfo(
      id: 'INT_2',
      title: '중급 2',
      subtitle: '단어 읽기와 조합 연습',
      group: _LevelGroup.intermediate,
    ),
    _LearningLevelInfo(
      id: 'ADV_1',
      title: '고급 1',
      subtitle: '문장 읽기 연습',
      group: _LevelGroup.advanced,
    ),
    _LearningLevelInfo(
      id: 'ADV_2',
      title: '고급 2',
      subtitle: '실전 점자 학습',
      group: _LevelGroup.advanced,
    ),
  ];

  @override
  void initState() {
    super.initState();

    /// Drawer에서 Chat/Settings 탭으로 직접 진입할 때 사용
    ///
    /// 잘못된 index가 들어와도 앱이 깨지지 않도록 0~3 범위로 제한
    _selectedIndex = widget.initialIndex.clamp(0, 3).toInt();

    _loadDashboardData();
  }

  /// 홈 대시보드 데이터 로드
  ///
  /// UI는 저장소 구현체를 직접 알지 않고 서비스 결과만 사용
  Future<void> _loadDashboardData() async {
    final results = await Future.wait<Object>([
      ProgressService.getLevelProgressMap(),
      StreakService.getStreak(),
      XpService.getTotalXp(),
    ]);

    if (!mounted) return;

    setState(() {
      _progressMap = results[0] as Map<String, double>;
      _dailyStreak = results[1] as int;
      _totalXp = results[2] as int;
    });
  }

  /// 탭 이동 전 진행 중인 음성 정리
  ///
  /// 화면 이동 시 TTS 겹침 방지
  void _stopScreenAudio() {
    unawaited(TtsManager.instance.stopAll());
    unawaited(AppTtsService().stop());
  }

  /// 하단 네비게이션 탭 변경
  ///
  /// Practice 탭은 선택된 순간에만 생성
  void _onTapNav(int index) {
    _stopScreenAudio();

    setState(() => _selectedIndex = index);

    if (index == 0) {
      unawaited(_loadDashboardData());
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _goHome() {
    _onTapNav(0);
  }

  void _openChat() {
    _onTapNav(2);
  }

  void _openSettings() {
    _onTapNav(3);
  }

  Future<void> _openLevel(_LearningLevelInfo level) async {
    _stopScreenAudio();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CurriculumSelectionScreen(
          levelId: level.id,
          levelTitle: level.title,
        ),
      ),
    );

    if (!mounted) return;
    await _loadDashboardData();
  }

  /// 레벨 잠금 조건
  ///
  /// 입문 완료 후 초급 진입
  /// 초급/중급은 이전 그룹 평균 50% 이상 시 다음 그룹 진입
  bool _isUnlocked(_LearningLevelInfo level) {
    switch (level.group) {
      case _LevelGroup.intro:
        return true;

      case _LevelGroup.beginner:
        return (_progressMap['ENT_1'] ?? 0) >= 1.0;

      case _LevelGroup.intermediate:
        final beginnerAverage =
            ((_progressMap['BAS_1'] ?? 0) + (_progressMap['BAS_2'] ?? 0)) / 2;
        return beginnerAverage >= 0.5;

      case _LevelGroup.advanced:
        final intermediateAverage =
            ((_progressMap['INT_1'] ?? 0) + (_progressMap['INT_2'] ?? 0)) / 2;
        return intermediateAverage >= 0.5;
    }
  }

  /// 선택된 탭만 생성
  ///
  /// IndexedStack 사용 시 Practice가 앱 시작부터 생성되어 권한 TTS가 실행됨
  Widget _buildSelectedTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();

      case 1:
        return const PracticeScreen();

      case 2:
        return ChatScreen(onBackPressed: _goHome);

      case 3:
        return SettingsScreen(
          onBackPressed: _goHome,
          isActive: true,
        );

      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final visibleLevels = _levels.take(4).toList();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _StatMiniCard(
                    label: '연속 학습일',
                    value: '$_dailyStreak일',
                    icon: Icons.local_fire_department_outlined,
                    iconColor: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatMiniCard(
                    label: '누적 경험치',
                    value: '$_totalXp XP',
                    icon: Icons.bolt_outlined,
                    iconColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              '이어서 학습하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            for (final level in visibleLevels) ...[
              _LevelCard(
                level: level,
                progress: _progressMap[level.id] ?? 0,
                isUnlocked: _isUnlocked(level),
                onTap: () => _openLevel(level),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
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
            const Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 28,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '커리큘럼 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '통합기획서 기준 학습 단계에 맞춰 점자를 차근차근 익혀보세요.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: '챗봇',
                    subtitle: '상담 화면으로 이동',
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF00AEEF),
                    onTap: _openChat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: '설정',
                    subtitle: '환경 설정',
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF6366F1),
                    onTap: _openSettings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navItems = [
      NavigationDestination(
        icon: Icon(Icons.school_outlined),
        label: 'Learn',
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_alt_outlined),
        label: 'Practice',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chat',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];

    const titles = ['PuzzleDot', '카메라 학습', 'PuzzleBot', '설정'];
    const subtitles = [
      '학습 대시보드',
      '카메라로 점자 연습',
      'PuzzleBot과 대화',
      '프로필 및 설정',
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: '메뉴 열기',
                    child: GestureDetector(
                      onTap: _openDrawer,
                      child: Container(
                        width: 48,
                        height: 48,
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
                        child: const Icon(
                          Icons.menu,
                          color: Color(0xFF0F172A),
                        ),
                      ),
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
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
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildSelectedTab(),
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

enum _LevelGroup {
  intro,
  beginner,
  intermediate,
  advanced,
}

/// 홈 화면 레벨 표시 모델
///
/// 화면 전용 데이터
/// 커리큘럼 원본 데이터와 UI 표시 문구 분리
class _LearningLevelInfo {
  final String id;
  final String title;
  final String subtitle;
  final _LevelGroup group;

  const _LearningLevelInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.group,
  });
}

class _LevelCard extends StatelessWidget {
  final _LearningLevelInfo level;
  final double progress;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.progress,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Semantics(
      button: isUnlocked,
      label: '${level.title} ${isUnlocked ? '진행률 $progressPercent퍼센트' : '잠금됨'}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: isUnlocked ? onTap : null,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
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
                    Expanded(
                      child: Text(
                        level.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Icon(
                      isUnlocked ? Icons.check_circle : Icons.lock,
                      size: 18,
                      color: isUnlocked
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  level.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: isUnlocked ? progress : 0,
                    minHeight: 10,
                    color: isUnlocked
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
                      isUnlocked ? '$progressPercent% 완료' : '잠금됨',
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnlocked
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(
                      isUnlocked ? Icons.arrow_forward_ios : Icons.lock,
                      size: 14,
                      color: isUnlocked
                          ? const Color(0xFF00AEEF)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title 이동',
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
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
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}