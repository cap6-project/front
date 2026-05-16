import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/chatbot_service.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ChatScreen({super.key, this.onBackPressed});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 초기 웰컴 메시지 세팅
  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          '안녕하세요! 점자 학습 챗봇입니다.\n"초급 학습 보여줘" 혹은 "점자의 역사가 궁금해" 등 자유롭게 말씀해 주세요!',
      'isBot': true,
    },
  ];

  // STT 및 인스턴스 상태 관리 변수
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤을 항상 가장 아래(최신 대화)로 이동시키는 헬퍼 메서드
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isBot': false});
    });
    _scrollToBottom();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add({'text': text, 'isBot': true});
    });
    _scrollToBottom();
  }

  /// 텍스트 입력 및 LLM 연동 메인 처리 로직
  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _addUserMessage(text);
    _controller.clear();

    setState(() {
      _isLoading = true;
    });

    // LLM 통신 요청 수행
    final llmResult = await ChatbotService.sendMessageToLLM(text);

    setState(() {
      _isLoading = false;
    });

    // LLM 답변 화면에 빌드
    _addBotMessage(llmResult['reply']!);

    // 라우팅 결과(딥링크 키워드)가 들어있다면 지연 후 화면 이동 수행
    final route = llmResult['route']!;
    if (route.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          ChatbotService.navigateByRoute(route, context);
        }
      });
    }
  }

  /// STT 음성 입력 기능 처리 로직
  void _handleVoiceInput() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('음성 인식 오류: ${errorNotification.errorMsg}')),
          );
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
            // 음성 입력이 완전히 끝나면 자동으로 메시지 전송 실행
            if (result.finalResult) {
              setState(() => _isListening = false);
              _handleSend();
            }
          },
          localeId: 'ko_KR', // 한국어 인식 강제 지정
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 기기에서 음성 인식을 사용할 수 없습니다.')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 상단 바 상단 레이아웃
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
                    // 음성 인식 중일 때 마이크 아이콘 색상 하이라이팅 변경
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 26,
                      color: _isListening ? Colors.redAccent : Colors.black87,
                    ),
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

          // 대화 리스트 영역
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0), // 로딩 아이템 카운트 추가
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                // 로딩 인디케이터 조건 분기 처리
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00AEEF),
                        ),
                      ),
                    ),
                  );
                }

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
            ),
          ),

          // 하단 텍스트 필드 입력부
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
                      hintText: _isListening
                          ? '말씀 내용을 듣고 있습니다...'
                          : '질문을 자유롭게 입력해보세요.',
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
