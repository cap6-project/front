import 'dart:io'; // 파일 생성을 위해 추가됨
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // 추가됨

class SettingsScreen extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback? onBackPressed;

  const SettingsScreen({
    super.key,
    required this.selectedIndex,
    this.onBackPressed,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 변수 및 상태 관리
  late FlutterTts _tts;
  final ImagePicker _picker = ImagePicker(); // 이미지 피커 인스턴스 추가
  String? _profileImagePath; // 선택된 프로필 이미지 경로 저장 (추가됨)
  int _completedCount = 0;

  double _speechRate = 1.0;
  double _volume = 1.0;
  bool _vibrationEnabled = true;
  bool _isPlayingSample = false;

  bool _studyReminderEnabled = true;
  bool _messageNoticeEnabled = true;

  static const int _totalLevels = 78;
  static const String appVersion = '1.0.0';
  static const String modelVersion = '2.1.0';
  static const String lastUpdateDate = '2026-04-11';

  static const int _introTotal = 15;
  static const int _beginnerTotal = 25;
  static const int _intermediateTotal = 23;
  static const int _advancedTotal = 15;

  int _introCompleted = 0;
  int _beginnerCompleted = 0;
  int _intermediateCompleted = 0;
  int _advancedCompleted = 0;

  // 화면 진입/이탈/생성

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _safeInitSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex == 2) {
      _initializeAndPlay();
    } else {
      _stopTts();
    }
  }

  @override
  void dispose() {
    _stopTts();
    super.dispose();
  }

  // [기능] 이미지 선택 및 화면 적용 로직 추가
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      // 이미지 선택 후 처리 로직
      debugPrint("선택한 이미지 경로: ${image.path}");

      // 상태 업데이트를 통해 화면에 즉시 반영 (추가됨)
      setState(() {
        _profileImagePath = image.path;
      });

      // [TODO] 실제 앱에서는 여기서 이미지 파일을 서버로 업로드하는 로직이 필요합니다.
    }
  }

  // TTS 제어 및 데이터 비즈니스 로직
  void _safeInitSettings() async {
    await _loadPreferences();
    await _initializeTts();
    if (mounted && widget.selectedIndex == 2) {
      _speakProgress();
    }
  }

  void _initializeAndPlay() async {
    await _loadPreferences();
    await _initializeTts();
    if (mounted && widget.selectedIndex == 2) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && widget.selectedIndex == 2) {
        _speakProgress();
      }
    }
  }

  // [TODO] 전역 TTS 설정 연동

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(_speechRate / 2.7);
      await _tts.setVolume(_volume);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doneKeys = prefs.getKeys().where((key) => key.startsWith('done_'));
      final completed = doneKeys
          .where((key) => prefs.getBool(key) == true)
          .length;
      final vibration = prefs.getBool('vibration_enabled') ?? true;
      final speechRate = prefs.getDouble('tts_speech_rate') ?? 1.0;
      final volume = prefs.getDouble('tts_volume') ?? 1.0;
      final studyReminder = prefs.getBool('study_reminder_enabled') ?? true;
      final messageNotice = prefs.getBool('message_notice_enabled') ?? true;
      // [TODO] 실제 앱에서는 SharedPreferences나 데이터베이스에 저장된 프로필 이미지 경로도 불러와야 합니다.
      // _profileImagePath = prefs.getString('profile_image_path');

      int tempCount = completed;
      int intro = tempCount >= _introTotal ? _introTotal : tempCount;
      tempCount -= intro;
      int beginner = tempCount >= _beginnerTotal ? _beginnerTotal : tempCount;
      tempCount -= beginner;
      int inter = tempCount >= _intermediateTotal
          ? _intermediateTotal
          : tempCount;
      tempCount -= inter;
      int advanced = tempCount >= _advancedTotal ? _advancedTotal : tempCount;

      if (mounted) {
        setState(() {
          _completedCount = completed;
          _vibrationEnabled = vibration;
          _speechRate = speechRate;
          _volume = volume;
          _studyReminderEnabled = studyReminder;
          _messageNoticeEnabled = messageNotice;
          _introCompleted = intro;
          _beginnerCompleted = beginner;
          _intermediateCompleted = inter;
          _advancedCompleted = advanced;
        });
      }
    } catch (_) {}
  }

  Future<void> _speakProgress() async {
    if (_isPlayingSample || widget.selectedIndex != 2) return;
    final message =
        '전체 $_totalLevels개 중 $_completedCount개 완료했습니다. '
        '입문 $_introTotal개 중 $_introCompleted개, '
        '초급 $_beginnerTotal개 중 $_beginnerCompleted개, '
        '중급 $_intermediateTotal개 중 $_intermediateCompleted개, '
        '고급 $_advancedTotal개 중 $_advancedCompleted개 완료했습니다.';
    if (mounted) setState(() => _isPlayingSample = true);
    try {
      await _tts.setSpeechRate(_speechRate / 2.7);
      await _tts.setVolume(1.0);
      await _tts.speak(message);
    } catch (_) {}
    int delayDuration = (14000 / _speechRate).round();
    await Future.delayed(Duration(milliseconds: delayDuration));
    if (mounted) setState(() => _isPlayingSample = false);
  }

  Future<void> _stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {}
    if (mounted) setState(() => _isPlayingSample = false);
  }

  Future<void> _savePreference(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  // 사용자 인터랙션 처리
  void _updateSpeechRate(double value) {
    setState(() => _speechRate = value);
    _savePreference('tts_speech_rate', value);
    _tts.setSpeechRate(value / 2.7);
  }

  void _updateVolume(double value) {
    setState(() => _volume = value);
    _savePreference('tts_volume', value);
    _tts.setVolume(value); 
  }

  void _toggleVibration(bool value) {
    setState(() => _vibrationEnabled = value);
    _savePreference('vibration_enabled', value);
    if (value) HapticFeedback.heavyImpact();
  }

  // UI 메인 빌드 (레이아웃 구조)

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _stopTts();
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF0F172A),
            ),
            onPressed: () async {
              await _stopTts();
              widget.onBackPressed != null
                  ? widget.onBackPressed!()
                  : Navigator.of(context).pop();
            },
          ),
          title: const Text(
            '설정',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildProfileSection(),
                const SizedBox(height: 16),
                const Text(
                  '알렉스',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    // [TODO] 실제 앱에서는 여기서 사용자의 실제 이름을 표시하도록 수정해야 합니다.
                  ),
                ),
                const SizedBox(height: 24),
                _buildProgressBox(),
                const SizedBox(height: 14),
                _buildReplayBox(),
                const SizedBox(height: 24),
                _buildSettingsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 모듈화된 UI 컴포넌트 메서드

  Widget _buildProfileSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFEEF8FF),
              // 선택된 이미지가 있으면 보여주고, 없으면 기본 아이콘 표시 (수정됨)
              backgroundImage: _profileImagePath != null
                  ? FileImage(File(_profileImagePath!))
                  : null,
              child: _profileImagePath == null
                  ? const Icon(Icons.person, size: 56, color: Color(0xFF2563EB))
                  : null,
            ),
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.5 - 55,
          bottom: 4,
          child: GestureDetector(
            onTap: _showProfileEditOptions,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              _buildSliderRow(
                icon: Icons.volume_up,
                title: '음량',
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: _updateVolume,
                displayValue: '${(_volume * 100).toStringAsFixed(0)}%',
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF1F5F9),
              ),
              _buildSliderRow(
                icon: Icons.speed,
                title: '음성 속도',
                value: _speechRate,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: _updateSpeechRate,
                displayValue: '${_speechRate.toStringAsFixed(1)}x',
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF1F5F9),
              ),
              _buildToggleRow(
                icon: Icons.vibration,
                title: '진동 피드백',
                value: _vibrationEnabled,
                onChanged: _toggleVibration,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 2,
                ),
                leading: const Icon(
                  Icons.notifications_none_outlined,
                  color: Color(0xFF2563EB),
                ),
                title: const Text(
                  '알림 설정',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showNotificationSettings,
              ),
              const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF1F5F9),
              ),
              _buildInfoRow(
                icon: Icons.info_outline,
                title: '앱 정보',
                subtitle:
                    '버전: $appVersion / 모델: $modelVersion\n최종 업데이트: $lastUpdateDate',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Color(0xFF2563EB),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '학습 진도',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // [TODO]
          // 현재 값(_completedCount, _totalLevels 등)은 로직 예시용입니다.
          // 실제 학습하기 화면에서 퀴즈 결과를 저장한 'done_{levelId}' 키들을
          // SharedPreferences에서 실시간으로 불러와서 실제 진척도를 표시하도록 수정해야 합니다.
          Text(
            '전체 진도: $_completedCount/$_totalLevels',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // [TODO] 단계별(입문/초급/중급/고급) 분류 기준도 학습하기 데이터와
              // 일치하도록 'levelId' 접두사나 분류 체계를 맞춰서 데이터를 파싱해야 합니다.
              _buildProgressBadge('입문', '$_introCompleted/$_introTotal'),
              _buildProgressBadge('초급', '$_beginnerCompleted/$_beginnerTotal'),
              _buildProgressBadge(
                '중급',
                '$_intermediateCompleted/$_intermediateTotal',
              ),
              _buildProgressBadge('고급', '$_advancedCompleted/$_advancedTotal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildReplayBox() {
    return InkWell(
      onTap: _isPlayingSample ? null : _speakProgress,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                _isPlayingSample ? Icons.volume_up : Icons.replay,
                color: const Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '진도 안내 다시듣기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPlayingSample ? '현재 오디오가 재생 중입니다.' : '터치하면 안내 음성이 재생됩니다.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String displayValue,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF2563EB),
            inactiveColor: const Color(0xFFE2E8F0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // 모달 및 팝업창 로직
  void _showProfileEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '프로필 사진 설정',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              // 카메라 열기
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
                title: const Text(
                  '카메라 열기',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              // 갤러리에서 선택하기
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2563EB),
                ),
                title: const Text(
                  '갤러리에서 선택하기',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  '현재 사진 삭제',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  // 현재 사진 삭제 로직 (수정됨)
                  Navigator.pop(context);
                  if (_profileImagePath != null) {
                    setState(() {
                      _profileImagePath = null; // 경로 초기화하여 기본 아이콘으로 복원
                    });
                    // [TODO] 실제 앱에서는 여기서 서버에 저장된 프로필 이미지 삭제 요청을 보내야 합니다.
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '알림 세부 설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text(
                      '학습 리마인더 알림',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      '정기적인 퀴즈 및 학습 유도 안내를 받습니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _studyReminderEnabled,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (bool value) {
                      setModalState(() => _studyReminderEnabled = value);
                      setState(() => _studyReminderEnabled = value);
                      _savePreference('study_reminder_enabled', value);
                    },
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),
                  SwitchListTile(
                    title: const Text(
                      '메시지 알림',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      '중요 공지사항 및 시스템 메시지 알림을 받습니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _messageNoticeEnabled,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (bool value) {
                      setModalState(() => _messageNoticeEnabled = value);
                      setState(() => _messageNoticeEnabled = value);
                      _savePreference('message_notice_enabled', value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
