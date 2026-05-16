import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_dot/services/tts_manager.dart';
import 'package:image_picker/image_picker.dart'; // 패키지 임포트 필요

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final bool isActive;

  const SettingsScreen({super.key, this.onBackPressed, required this.isActive});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  int _completedCount = 0;

  // 단계별 문제 수 및 완료 수
  final int _entireCount = 78;
  int _entireDone = 0;
  int _entryCount = 0, _entryDone = 0;
  int _basicCount = 0, _basicDone = 0;
  int _interCount = 0, _interDone = 0;
  int _advCount = 0, _advDone = 0;

  double _speechRate = 0.8;
  double _volume = 1.0;
  bool _vibrationEnabled = true;
  bool _isPlayingSample = false;

  // 프로필 이미지 경로 상태 관리 (기본 테스트 url)
  String _profileImageUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';

  static const String appVersion = '1.0.0';
  static const String modelVersion = '2.1.0';

  @override
  void initState() {
    super.initState();
    TtsManager.instance.register(_tts);
    _initializeTts();
    _prepareSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _speakProgress();
    }
    if (oldWidget.isActive && !widget.isActive) {
      _stopTts();
    }
  }

  Future<void> _prepareSettings() async {
    await _loadPreferences();
    await _calculateProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isActive) {
        _speakProgress();
      }
    });
  }

  Future<void> _stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _isPlayingSample = false);
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final doneKeys = prefs.getKeys().where((key) => key.startsWith('done_'));
    final completed = doneKeys
        .where((key) => prefs.getBool(key) == true)
        .length;

    int entryCount = 0, entryDone = 0;
    int basicCount = 0, basicDone = 0;
    int interCount = 0, interDone = 0;
    int advCount = 0, advDone = 0;

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('done_')) continue;
      if (key.contains('ENT_')) entryCount++;
      if (key.contains('BAS_')) basicCount++;
      if (key.contains('INT_')) interCount++;
      if (key.contains('ADV_')) advCount++;
      if (prefs.getBool(key) == true) {
        if (key.contains('ENT_')) entryDone++;
        if (key.contains('BAS_')) basicDone++;
        if (key.contains('INT_')) interDone++;
        if (key.contains('ADV_')) advDone++;
      }
    }
    final vibration = prefs.getBool('vibration_enabled') ?? true;
    final speechRate = prefs.getDouble('tts_speech_rate') ?? _speechRate;
    final volume = prefs.getDouble('tts_volume') ?? _volume;

    setState(() {
      _completedCount = completed;
      _entireDone = completed;
      _entryCount = entryCount;
      _entryDone = entryDone;
      _basicCount = basicCount;
      _basicDone = basicDone;
      _interCount = interCount;
      _interDone = interDone;
      _advCount = advCount;
      _advDone = advDone;
      _vibrationEnabled = vibration;
      _speechRate = speechRate;
      _volume = volume;
    });
  }

  Future<void> _calculateProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final doneKeys = prefs.getKeys().where((key) => key.startsWith('done_'));
    final completed = doneKeys
        .where((key) => prefs.getBool(key) == true)
        .length;
    if (mounted) {
      setState(() => _completedCount = completed);
    }
  }

  Future<void> _speakProgress() async {
    if (!widget.isActive) return;

    final message =
        '전체 $_entireCount개 중 $_entireDone개 완료, '
        '입문 $_entryCount개 중 $_entryDone개 완료, '
        '초급 $_basicCount개 중 $_basicDone개 완료, '
        '중급 $_interCount개 중 $_interDone개 완료, '
        '고급 $_advCount개 중 $_advDone개 완료 하였습니다.';

    setState(() => _isPlayingSample = true);
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.speak(message);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 5000));
    if (mounted) {
      setState(() => _isPlayingSample = false);
    }
  }

  Future<void> _savePreference(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  void _toggleVibration(bool value) {
    setState(() => _vibrationEnabled = value);
    _savePreference('vibration_enabled', value);
    if (value) {
      HapticFeedback.heavyImpact();
    }
  }

  void _updateSpeechRate(double value) async {
    setState(() => _speechRate = value);
    _savePreference('tts_speech_rate', value);
    await _tts.setSpeechRate(value);
    if (_isPlayingSample) {
      await _stopTts();
      _speakProgress();
    }
  }

  void _updateVolume(double value) async {
    setState(() => _volume = value);
    _savePreference('tts_volume', value);
    await _tts.setVolume(value);
    if (_isPlayingSample) {
      await _stopTts();
      _speakProgress();
    }
  }

  // 카메라 혹은 앨범에서 사진 가져오는 함수
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          // 로컬 파일 경로 혹은 업로드 로직 처리 영역 (여기서는 UI 갱신을 보여주기 위해 경로 지정)
          // 실제 파일 표시 시에는 FileImage(File(pickedFile.path)) 구조를 권장합니다.
          _profileImageUrl = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint("이미지 선택 에러: $e");
    }
  }

  // 하단 프로필 사진 설정 모달 시트 바텀 스케줄링
  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '프로필 사진 수정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF64748B),
                ),
                title: const Text(
                  '갤러리에서 선택',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF64748B),
                ),
                title: const Text(
                  '카메라 사용',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  '현재 사진 제거',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    // 기본 이미지 플레이스홀더 주소나 비어있는 상태로 회귀
                    _profileImageUrl =
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';
                  });
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }

  Future<bool> _handlePop() async {
    await _stopTts();
    return true;
  }

  @override
  void dispose() {
    TtsManager.instance.unregister(_tts);
    _stopTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handlePop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF0F172A),
                      ),
                      onPressed: () {
                        _stopTts();
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                    const Spacer(),
                    const Text(
                      '내 정보 및 설정',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),

                // 프로필 영역 (클릭 피드백 적용 추가)
                Column(
                  children: [
                    GestureDetector(
                      onTap: _showProfileModal, // 아바타 박스 전체 탭 인식 추가
                      child: Stack(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              image: DecorationImage(
                                image: _profileImageUrl.startsWith('http')
                                    ? NetworkImage(_profileImageUrl)
                                    : AssetImage(_profileImageUrl)
                                          as ImageProvider, // 로컬 경로 대응용
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '알렉스',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 상단 대시보드 카드
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 28,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'n일',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '연속 학습',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.stars,
                              color: Color(0xFF2563EB),
                              size: 28,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'n개',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '완료한 코스',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 학습 진도 요약 섹션
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '학습 진도',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _isPlayingSample ? null : _speakProgress,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: _isPlayingSample
                                      ? Colors.grey
                                      : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isPlayingSample ? '재생 중' : '다시 재생',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isPlayingSample
                                        ? Colors.grey
                                        : const Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '전체 완료: $_entireDone / $_entireCount',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '입문: $_entryDone/$_entryCount, 초급: $_basicDone/$_basicCount, 중급: $_interDone/$_interCount, 고급: $_advDone/$_advCount',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 음성 및 피드백 설정 영역
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 음량
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_up,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '음량',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(_volume * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        onChanged: _updateVolume,
                        activeColor: const Color(0xFF2563EB),
                        inactiveColor: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 10),

                      // 2. 음성 속도
                      Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '음성 속도',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_speechRate.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _speechRate,
                        min: 0.5,
                        max: 1.5,
                        divisions: 10,
                        onChanged: _updateSpeechRate,
                        activeColor: const Color(0xFF2563EB),
                        inactiveColor: const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFF1F5F9), thickness: 1.0),
                      const SizedBox(height: 6),

                      // 3. 진동 피드백 스위치
                      Row(
                        children: [
                          const Icon(
                            Icons.vibration,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '진동 피드백',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '정답/오답 시 진동 알림',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Switch(
                            value: _vibrationEnabled,
                            onChanged: _toggleVibration,
                            activeColor: const Color(0xFF2563EB),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 하단 일반 설정 목록 박스
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.notifications_none,
                        title: '알림',
                        subtitle: '학습 리마인더 및 메시지 알림',
                      ),
                      _buildSettingsRow(
                        icon: Icons.dark_mode_outlined,
                        title: '다크 모드',
                        subtitle: '어두운 테마 사용',
                        trailing: Switch(
                          value: false,
                          onChanged: (val) {},
                          activeColor: const Color(0xFF2563EB),
                        ),
                      ),
                      _buildSettingsRow(
                        icon: Icons.info_outline,
                        title: '앱 정보',
                        subtitle: '버전: $appVersion / 모델: $modelVersion',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
