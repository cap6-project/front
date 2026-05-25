import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import 'curriculum/curriculum_selection_screen.dart';
import 'settings_screen.dart';

/// 챗봇과 대화하는 화면입니다.
/// [onBackPressed]는 상위 네비게이션으로 돌아갈 때 호출되는 콜백입니다.
class ChatScreen extends StatefulWidget {
  final VoidCallback onBackPressed;

  const ChatScreen({super.key, required this.onBackPressed});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// 메시지 데이터 모델 - 다른 파트와 데이터를 주고받을 때 용이합니다.
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatBotService _chatbotService = ChatBotService();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // 초기 환영 메시지 설정
    _messages.add(
      ChatMessage(
        text: '안녕하세요! 무엇을 도와드릴까요?\n추천 키워드: 자음, 모음, 퀴즈, 복습, 설정',
        isUser: false,
      ),
    );
  }

  /// 메시지 전송 로직
  void _handleSubmitted() {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
    });
    _controller.clear();

    // 💡 챗봇 응답 로직: 다른 파트 개발자가 이 부분의 로직을 수정할 수 있습니다.
    final analysis = _chatbotService.analyzeMessage(userText);
    final botReply = analysis['reply']!;
    final targetRoute = analysis['route'];

    setState(() {
      _messages.add(ChatMessage(text: botReply, isUser: false));
    });

    if (targetRoute != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _navigateToTargetPage(targetRoute);
      });
    }
  }

  /// 페이지 이동 로직
  void _navigateToTargetPage(String route) {
    if (route == 'home') {
      widget.onBackPressed();
      return;
    }
    // 💡 실제 라우터 연결 시, 이 switch 문에서 각자의 화면 파일로 연결하세요.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _buildTargetPage(route)),
    );
  }

  Widget _buildTargetPage(String route) {
    switch (route) {
      case 'consonant':
        return const CurriculumSelectionScreen(
          levelId: 'BAS_1',
          levelTitle: '초급 1',
        );
      case 'vowel':
        return const CurriculumSelectionScreen(
          levelId: 'BAS_2',
          levelTitle: '초급 2',
        );
      case 'word':
        return const CurriculumSelectionScreen(
          levelId: 'INT_1',
          levelTitle: '중급 1',
        );
      case 'sentence':
        return const CurriculumSelectionScreen(
          levelId: 'INT_2',
          levelTitle: '중급 2',
        );
      case 'beginner':
        return const CurriculumSelectionScreen(
          levelId: 'ENT_1',
          levelTitle: '입문 1',
        );
      case 'advanced':
        return const CurriculumSelectionScreen(
          levelId: 'ADV_1',
          levelTitle: '고급 1',
        );
      case 'settings':
        return SettingsScreen(
          selectedIndex: 3,
          onBackPressed: () => Navigator.pop(context),
        );
      default:
        return Scaffold(
          appBar: AppBar(title: Text('$route 화면')),
          body: Center(child: Text('[$route] 페이지 준비 중입니다.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  ChatMessageBubble(msg: _messages[index]),
            ),
          ),
          const Divider(height: 1.0),
          ChatInputArea(controller: _controller, onSubmitted: _handleSubmitted),
        ],
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    title: const Text(
      'PuzzleBot',
      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
    ),
    backgroundColor: Colors.white,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new,
        color: Color(0xFF0F172A),
        size: 20,
      ),
      onPressed: () {
        FocusScope.of(context).unfocus();
        widget.onBackPressed();
      },
    ),
  );
}

/// 메시지 말풍선 위젯 (재사용 및 분리)
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const ChatMessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(14.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser ? const Color(0xFF00AEEF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: msg.isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(18),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 15,
            color: msg.isUser ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// 하단 입력창 위젯 (재사용 및 분리)
class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: "메뉴 입력...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => onSubmitted(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFF00AEEF)),
              onPressed: onSubmitted,
            ),
          ],
        ),
      ),
    );
  }
}
