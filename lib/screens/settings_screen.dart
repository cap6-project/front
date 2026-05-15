import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:puzzle_dot/services/tts_manager.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final bool isActive;

  const SettingsScreen({super.key, this.onBackPressed, required this.isActive});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  int _completedCount = 0;
  // 단계별 문제 수 및 완료 수
  int _entireCount = 78;
  int _entireDone = 0;
  int _entryCount = 0, _entryDone = 0;
  int _basicCount = 0, _basicDone = 0;
  int _interCount = 0, _interDone = 0;
  int _advCount = 0, _advDone = 0;

  // 단계별 prefix
  final Map<String, String> _levelPrefixes = {
    'ENT_': '입문',
    'BAS_': '초급',
    'INT_': '중급',
    'ADV_': '고급',
  };
  double _speechRate = 0.8;
  double _volume = 1.0;
  bool _vibrationEnabled = true;
  bool _isPlayingSample = false;
  static const int _totalLevels = 78;
  static const String appVersion = '1.0.0';
  static const String modelVersion = '2.1.0';
  static const String lastUpdateDate = '2026-04-11';

  @override
  void initState() {
    super.initState();
    TtsManager.instance.register(_tts);
    _initializeTts();
    _prepareSettings();
  }

  Future<void> _prepareSettings() async {
    await _loadPreferences();
    await _calculateProgress();
    if (mounted) {
      _speakProgress();
    }
  }

  Future<void> _stopTts() async {
    try {
      await _tts.stop();
    } catch (_) {
      // ignore
    }
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
    } catch (_) {
      // TTS 초기화 실패 시 무시
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final doneKeys = prefs.getKeys().where((key) => key.startsWith('done_'));
    final completed = doneKeys
        .where((key) => prefs.getBool(key) == true)
        .length;

    // 단계별 카운트 초기화
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
    // 안내 메시지 생성
    final message =
        '전체 $_entireCount개 중 $_entireDone개, '
        '입문 $_entryDone/$_entryCount, '
        '초급 $_basicDone/$_basicCount, '
        '중급 $_interDone/$_interCount, '
        '고급 $_advDone/$_advCount 진행 중입니다.';

    setState(() => _isPlayingSample = true);
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.speak(message);
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 4000));
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

  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:support@puzzledot.com?subject=고객센터 문의');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이메일 앱을 열 수 없습니다.')));
      }
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

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
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
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onTap,
    required String semanticsLabel,
  }) {
    final tile = Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: tile,
      );
    } else {
      return tile;
    }
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required Gradient gradient,
    Color textColor = Colors.white,
    double height = 58,
  }) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22006CC3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
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
      onWillPop: () async {
        await _stopTts();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F4FF),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2563EB),
                      ),
                      iconSize: 28,
                      tooltip: '뒤로가기',
                      onPressed: () async {
                        await _stopTts();
                        if (widget.onBackPressed != null) {
                          widget.onBackPressed!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFEEF8FF),
                          child: Icon(
                            Icons.person,
                            size: 56,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: MediaQuery.of(context).size.width * 0.5 - 50,
                      bottom: 12,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '알렉스',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFF2563EB),
                              size: 28,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '전체 [4m$_entireDone[24m/[4m$_entireCount[24m',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '입문 $_entryDone/$_entryCount, 초급 $_basicDone/$_basicCount',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '중급 $_interDone/$_interCount, 고급 $_advDone/$_advCount',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '학습 진도',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _isPlayingSample ? null : _speakProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  _isPlayingSample ? Icons.volume_up : Icons.replay,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '다시듣기',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPlayingSample ? '재생 중...' : '진도 안내',
                              style: const TextStyle(
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
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.volume_up,
                        title: '음성 속도',
                        subtitle: 'TTS 재생 속도 조절',
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${_speechRate.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('음성 속도 조절'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: _speechRate,
                                    min: 0.5,
                                    max: 1.5,
                                    divisions: 10,
                                    label: '${_speechRate.toStringAsFixed(1)}x',
                                    onChanged: _updateSpeechRate,
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                  Text('${_speechRate.toStringAsFixed(1)}x'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildSettingsRow(
                        icon: Icons.volume_mute,
                        title: '음량',
                        subtitle: 'TTS 음성 크기',
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${(_volume * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('음량 조절'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    value: _volume,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 10,
                                    label:
                                        '${(_volume * 100).toStringAsFixed(0)}%',
                                    onChanged: _updateVolume,
                                    activeColor: const Color(0xFF2563EB),
                                  ),
                                  Text(
                                    '${(_volume * 100).toStringAsFixed(0)}%',
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _buildSettingsRow(
                        icon: Icons.vibration,
                        title: '진동 피드백',
                        subtitle: '정답/오답 시 진동 알림',
                        trailing: Switch(
                          value: _vibrationEnabled,
                          onChanged: _toggleVibration,
                          activeColor: const Color(0xFF2563EB),
                        ),
                      ),
                      _buildSettingsRow(
                        icon: Icons.email_outlined,
                        title: '고객 지원',
                        subtitle: '문제 및 피드백 전송',
                        onTap: _sendEmail,
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
