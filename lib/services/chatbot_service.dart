import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../screens/level_detail_screen.dart';
import '../screens/settings_screen.dart';

class ChatbotService {
  // TODO: 실제 발급받은 Gemini API Key를 여기에 입력하세요.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// 사용자의 메시지를 LLM에 보내고 { reply: "답변", route: "키워드" } 형태의 구조화된 응답을 받습니다.
  static Future<Map<String, String>> sendMessageToLLM(
    String userMessage,
  ) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        return {
          'reply':
              '서비스 연결을 위해 chatbot_service.dart 파일에 Gemini API Key 설정이 필요합니다.',
          'route': '',
        };
      }

      // LLM이 답변과 라우팅 인텐트를 정확한 JSON 객체로 반환하도록 가이드하는 프롬프트
      const systemPrompt = """
      당신은 점자 학습 앱의 친절한 도우미 챗봇입니다.
      사용자의 질문에 친절하고 부드러운 어조로 답변해 주세요.
      
      [핵심 기능: 라우팅 감지]
      사용자가 특정 학습 단계('입문', '초급', '중급', '고급')나 '설정' 화면으로 이동하고 싶어하는 의도가 대화 속에서 명확히 보인다면, 
      반드시 아래 정의된 단어 중 정확히 하나를 골라 'route' 필드에 넣어주세요. 
      사용자에게 단순히 개념을 설명하는 중이거나 화면 이동 의도가 없다면 'route' 필드는 반드시 빈 문자열("")이어야 합니다.
      - 허용된 route 단어: 입문, 초급, 중급, 고급, 설정
      
      반드시 JSON 형식을 엄격히 준수하여 아래와 같은 구조로만 응답하세요. 다른 설명이나 마크다운 텍스트를 섞지 마세요:
      {
        "reply": "사용자에게 전달할 친절한 답변 텍스트",
        "route": "감지된 단어 또는 빈 문자열"
      }
      """;

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": "$systemPrompt\n\n사용자 메시지: $userMessage"},
              ],
            },
          ],
          "generationConfig": {
            "responseMimeType": "application/json", // 응답을 JSON 형식으로 강제 유도
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String rawJson =
            data['candidates'][0]['content']['parts'][0]['text'];

        // 간혹 포함될 수 있는 마크다운 블록 래퍼 정제
        final cleanedJson = rawJson
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> parsed = jsonDecode(cleanedJson);

        return {
          'reply': parsed['reply']?.toString() ?? '죄송해요, 답변을 구성하지 못했어요.',
          'route': parsed['route']?.toString() ?? '',
        };
      } else {
        return {
          'reply': '서버와 통신 중 통신 에러(Status: ${response.statusCode})가 발생했습니다.',
          'route': '',
        };
      }
    } catch (e) {
      print('LLM 연동 에러: $e');
      return {
        'reply': '죄송합니다. 현재 챗봇 연결이 원활하지 않습니다. 잠시 후 다시 시도해 주세요.',
        'route': '',
      };
    }
  }

  /// 라우팅 키워드에 따라 딥링크 화면 이동을 처리합니다.
  static void navigateByRoute(String route, BuildContext context) {
    if (route == '입문') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: 'ENT_001',
            stageTitle: '입문',
            stageDescription: '처음 시작하는 학습자를 위한 입문 단계입니다.',
          ),
        ),
      );
    } else if (route == '초급') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: 'BAS_001',
            stageTitle: '초급',
            stageDescription: '기본 개념을 다지는 초급 단계입니다.',
          ),
        ),
      );
    } else if (route == '중급') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: 'INT_001',
            stageTitle: '중급',
            stageDescription: '응용과 반복 학습이 필요한 중급 단계입니다.',
          ),
        ),
      );
    } else if (route == '고급') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LevelDetailScreen(
            levelId: 'ADV_001',
            stageTitle: '고급',
            stageDescription: '도전 과제를 해결하는 고급 단계입니다.',
          ),
        ),
      );
    } else if (route == '설정') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen(isActive: true)),
      );
    }
  }
}
