import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/wine.dart';

// Replace with your key from https://aistudio.google.com/
// For production: route requests through a backend to protect the key.
const _kGeminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'YOUR_GEMINI_API_KEY',
);

class SommelierChat {
  final ChatSession _session;

  SommelierChat(this._session);

  Future<String> send(String message) async {
    final response = await _session.sendMessage(Content.text(message));
    return response.text ?? '죄송합니다. 다시 시도해주세요.';
  }
}

class GeminiService {
  static const _systemPrompt = '''
당신은 친절하고 지식이 풍부한 와인 소믈리에 에이전트입니다.
사용자의 와인 기록과 취향(산도, 탄닌, 바디감, 당도 등)을 바탕으로 맞춤 추천을 드립니다.
"지난번에 마신 샤도네이가 너무 셨어"처럼 피드백을 기억하고, 다음 추천에 반영해야 합니다.
답변은 반드시 한국어로, 친근하고 간결하게(200자 이내) 작성합니다.
''';

  Future<WineInfo?> analyzeLabel(File imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _kGeminiApiKey,
    );

    final imageBytes = await imageFile.readAsBytes();
    const prompt = '''
이 와인 라벨을 분석하고 아래 JSON 형식으로만 응답하세요 (코드 블록 없이 순수 JSON):
{"name":"와인 전체 이름","origin":"원산지(국가, 지역)","grape":"포도 품종","characteristics":"특징(한 문장, 한국어)","foodPairing":["음식1","음식2","음식3"]}
확인 불가 시 "알 수 없음"으로 표시하세요.
''';

    try {
      final response = await model.generateContent([
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ]),
      ]);

      final text = response.text;
      if (text == null) return null;

      final jsonStr = text
          .replaceAll(RegExp(r'```json|```'), '')
          .trim();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WineInfo.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  SommelierChat startChat(List<Wine> wineHistory) {
    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _kGeminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
    );

    final historyContext = _buildHistory(wineHistory);
    final session = model.startChat(history: [
      Content.user(historyContext),
      Content.model(
          '네! 기록을 확인했어요 🍷 취향을 파악했으니 언제든 추천 요청해주세요.'),
    ]);

    return SommelierChat(session);
  }

  String _buildHistory(List<Wine> wines) {
    if (wines.isEmpty) return '아직 와인 기록이 없습니다.';
    final lines = wines.take(20).map((w) {
      final parts = ['${w.name} (${w.origin} / ${w.grape})'];
      if (w.rating != null) parts.add('평점 ${w.rating}/5');
      if (w.review != null && w.review!.isNotEmpty) parts.add('후기: ${w.review}');
      return '• ${parts.join(', ')}';
    });
    return '내가 마신 와인 기록:\n${lines.join('\n')}';
  }
}
