import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'level_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ChatScreen({super.key, this.onBackPressed});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': '안녕하세요! 점자 학습 챗봇입니다. 궁금한 내용을 입력해 주세요.', 'isBot': true},
  ];

  static const Map<String, Map<String, String>> _keywordMap = {
    '입문': {'id': 'ENT_001', 'title': '입문'},
    '초급': {'id': 'BAS_001', 'title': '초급'},
    '중급': {'id': 'INT_001', 'title': '중급'},
    '고급': {'id': 'ADV_001', 'title': '고급'},
  };

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isBot': false});
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isBot': true});
    });
  }

  void _navigateToLearning(String levelId, String stageTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelDetailScreen(
          levelId: levelId,
          stageTitle: stageTitle,
          stageDescription: '$stageTitle 단계로 바로 이동합니다.',
        ),
      ),
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _controller.clear();

    final match = _keywordMap.entries.firstWhere(
      (entry) => text.contains(entry.key),
      orElse: () => const MapEntry('', {'id': '', 'title': ''}),
    );

    final keywordId = match.value['id'] ?? '';
    final keywordTitle = match.value['title'] ?? '';

    if (keywordId.isNotEmpty) {
      _addBotMessage('$keywordTitle 학습 화면으로 이동합니다. 잠시만 기다려 주세요.');
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _navigateToLearning(keywordId, keywordTitle),
      );
      return;
    }

    _addBotMessage('좋은 질문이에요. 점자 학습과 관련된 키워드(입문, 초급)를 입력해 보세요.');
  }

  void _handleVoiceInput() {
    _addUserMessage('음성 입력을 시도합니다.');
    _addBotMessage('음성 입력 기능은 지금은 준비 중입니다. 텍스트로도 입력할 수 있어요.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: '뒤로가기',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        widget.onBackPressed ??
                        () => Navigator.maybePop(context),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.arrow_back_ios_new, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    '챗봇 학습 도우미',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                Semantics(
                  button: true,
                  label: '음성 입력 버튼',
                  child: IconButton(
                    onPressed: _handleVoiceInput,
                    icon: const Icon(Icons.mic_none, size: 26),
                    splashRadius: 24,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isBot = message['isBot'] as bool;
                return Align(
                  alignment: isBot
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isBot
                            ? const Color(0xFFF3F8FF)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isBot ? 0 : 18),
                          bottomRight: Radius.circular(isBot ? 18 : 0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        message['text'] as String,
                        style: TextStyle(
                          color: isBot
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: _messages.length,
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: '입문, 초급 등을 입력하세요',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: '전송 버튼',
                  child: InkWell(
                    onTap: _handleSend,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AEEF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
