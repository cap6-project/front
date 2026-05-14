import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  int _completedCount = 0;
  double _speechRate = 0.8;
  bool _vibrationEnabled = true;
  static const int _totalLevels = 78;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadPreferences();
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // TTS 초기화 실패 시 무시
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final doneKeys = prefs.getKeys().where((key) => key.startsWith('done_')); 
    final completed = doneKeys.where((key) => prefs.getBool(key) == true).length;
    final vibration = prefs.getBool('vibration_enabled') ?? true;
    final speechRate = prefs.getDouble('tts_speech_rate') ?? _speechRate;

    setState(() {
      _completedCount = completed;
      _vibrationEnabled = vibration;
      _speechRate = speechRate;
    });

    await _speakProgress();
  }

  Future<void> _speakProgress() async {
    final message = '전체 $_totalLevels개 중 $_completedCount개 완료했습니다. '
        '진도율을 다시 듣고 싶으면 진도율 다시 듣기 버튼을 누르세요.';
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.speak(message);
    } catch (_) {
      // ignore
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 앱을 열 수 없습니다.')),
        );
      }
    }
  }

  void _toggleVibration(bool value) {
    setState(() => _vibrationEnabled = value);
    _savePreference('vibration_enabled', value);
    if (value) {
      HapticFeedback.lightImpact();
    }
  }

  void _updateSpeechRate(double value) {
    setState(() => _speechRate = value);
    _savePreference('tts_speech_rate', value);
    _tts.setSpeechRate(value);
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback onTap,
    required String semanticsLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 22, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const Spacer(),
              child,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 26, offset: Offset(0, 14)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('진도율 안내', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text('전체 $_totalLevels개 중 $_completedCount개 완료', style: const TextStyle(fontSize: 18, color: Color(0xFF334155))),
                    const SizedBox(height: 12),
                    const Text(
                      '진입 시 자동으로 진도 상태를 음성으로 안내합니다. 필요한 메뉴를 선택해 주세요.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTile(
                    title: '진도율 다시 듣기',
                    subtitle: '현재 완료 상태를 다시 음성으로 안내합니다.',
                    semanticsLabel: '진도율 다시 듣기 버튼',
                    onTap: _speakProgress,
                    child: const Icon(Icons.volume_up, size: 36, color: Color(0xFF2563EB)),
                  ),
                  _buildTile(
                    title: 'TTS 속도 조절',
                    subtitle: '음성 안내 속도를 조절합니다.',
                    semanticsLabel: 'TTS 속도 조절 슬라이더',
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: _speechRate,
                          min: 0.4,
                          max: 1.2,
                          divisions: 8,
                          label: '${_speechRate.toStringAsFixed(1)}x',
                          onChanged: _updateSpeechRate,
                        ),
                        Text('${_speechRate.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  _buildTile(
                    title: '진동 피드백',
                    subtitle: '정답/오답 시 진동을 켜거나 끕니다.',
                    semanticsLabel: '진동 피드백 토글',
                    onTap: () => _toggleVibration(!_vibrationEnabled),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _vibrationEnabled ? '켜짐' : '꺼짐',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Switch(
                          value: _vibrationEnabled,
                          onChanged: _toggleVibration,
                        ),
                      ],
                    ),
                  ),
                  _buildTile(
                    title: '고객센터',
                    subtitle: '이메일로 문의하기',
                    semanticsLabel: '고객센터 이메일 문의 버튼',
                    onTap: _sendEmail,
                    child: const Icon(Icons.email_outlined, size: 36, color: Color(0xFF0B6E99)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: '설정 화면 닫기',
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('돌아가기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
