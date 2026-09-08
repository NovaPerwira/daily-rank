import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/models/gacha_reward_model.dart';
import 'package:uuid/uuid.dart';

class AiQuestService {
  static final _uuid = const Uuid();

  /// Generates a list of custom quests using AI based on user's prompt.
  static Future<List<QuestModel>> generateQuests(String userId, String promptText, {String category = 'habit'}) async {
    final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini';

    final prompt = '''
You are an expert productivity and life-coach AI in an RPG-style habit tracker app.
The user wants to set personal quests/tasks for today with the following focus: "$promptText".
Generate 3 to 5 highly productive, non-repetitive, and actionable tasks tailored to their request.
Make the tasks specific and achievable today.
Assign XP rewards between 10 to 50 for each task based on its difficulty.
Output ONLY a valid JSON array with this exact structure, nothing else:
[
  {
    "title": "Task description here (e.g., Read 1 chapter of Flutter docs)",
    "xpReward": 30
  }
]
''';

    String text = '';

    if (provider == 'openrouter') {
      text = await _parseWithOpenRouter(prompt);
    } else {
      text = await _parseWithGemini(prompt);
    }

    if (text.isEmpty) {
      throw Exception('Gagal mendapatkan response dari AI');
    }

    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final jsonArray = jsonDecode(text) as List<dynamic>;
      final today = DateTime.now();
      
      final quests = jsonArray.map((item) {
        final title = item['title']?.toString() ?? 'Custom Task';
        final xpReward = (item['xpReward'] as num?)?.toInt() ?? 20;

        return QuestModel(
          id: _uuid.v4(),
          userId: userId,
          category: category,
          title: title,
          xpReward: xpReward,
          completed: false,
          date: today,
        );
      }).toList();

      return quests;
    } catch (e) {
      throw Exception('Format JSON tidak sesuai: $e\nResponse: $text');
    }
  }

  static Future<String> _parseWithGemini(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak ditemukan di .env. Silakan tambahkan GEMINI_API_KEY Anda.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );

    final response = await model.generateContent([
      Content.text(prompt)
    ]);

    return response.text ?? '';
  }

  static Future<String> _parseWithOpenRouter(String prompt) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key OpenRouter tidak ditemukan di .env. Silakan tambahkan OPENROUTER_API_KEY Anda.');
    }

    final model = dotenv.env['OPENROUTER_MODEL'] ?? 'google/gemini-2.5-flash-lite';

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://github.com/novap/life_rank', 
        'X-Title': 'Life Rank',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': prompt
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API Error: ${response.statusCode} - ${response.body}');
    }

    final json = jsonDecode(response.body);
    return json['choices']?[0]?['message']?['content'] ?? '';
  }

  /// Generates a list of custom financial todos using AI based on user's prompt.
  static Future<List<FinancialTodo>> generateFinancialTodos(String userId, String promptText) async {
    final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini';

    final prompt = '''
You are an expert financial and life-coach AI in an RPG-style habit tracker app.
The user wants to set personal financial quests/tasks for today with the following focus: "$promptText".
Generate 3 to 5 highly productive, non-repetitive, and actionable financial tasks tailored to their request.
Make the tasks specific and achievable today (e.g. "Review monthly budget", "Save 50,000 IDR").
Assign points (XP rewards) between 10 to 50 for each task based on its difficulty.
Output ONLY a valid JSON array with this exact structure, nothing else:
[
  {
    "title": "Task title here (max 5 words)",
    "description": "Short description of the task",
    "points": 30,
    "icon": "💰"
  }
]
''';

    String text = '';

    if (provider == 'openrouter') {
      text = await _parseWithOpenRouter(prompt);
    } else {
      text = await _parseWithGemini(prompt);
    }

    if (text.isEmpty) {
      throw Exception('Gagal mendapatkan response dari AI');
    }

    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final jsonArray = jsonDecode(text) as List<dynamic>;
      final today = DateTime.now();
      
      final todos = jsonArray.map((item) {
        final title = item['title']?.toString() ?? 'Custom Task';
        final description = item['description']?.toString() ?? '';
        final points = (item['points'] as num?)?.toInt() ?? 20;
        final icon = item['icon']?.toString() ?? '🎯';

        return FinancialTodo(
          id: _uuid.v4(),
          userId: userId,
          title: title,
          desc: description,
          icon: icon,
          points: points,
          isCustom: true,
          todoDate: today,
        );
      }).toList();

      return todos;
    } catch (e) {
      throw Exception('Format JSON tidak sesuai: $e\nResponse: $text');
    }
  }

  /// Generates a custom Gacha Reward and motivation using AI
  static Future<GachaReward> generateCustomGachaReward(String userId, String rarity, int totalXp, int baseDropRate) async {
    final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini';

    // base xp guidelines for rarity
    int minXp = 50;
    int maxXp = 100;
    if (rarity == 'Rare') { minXp = 150; maxXp = 300; }
    else if (rarity == 'Epic') { minXp = 400; maxXp = 800; }
    else if (rarity == 'Legendary') { minXp = 1000; maxXp = 2000; }

    final prompt = '''
You are a fun AI in a gamified habit tracker app.
The user just opened a "Lucky Box" (Gacha) and won a $rarity item!
The user has $totalXp XP.
Generate a short, simple, fun item name related to money or investing (max 3-4 words), e.g. "Silver Piggy Bank" or "Crystal Coin".
Assign an XP reward amount between $minXp and $maxXp.
Provide an extremely short motivation message (max 1 sentence, under 10 words).

Output ONLY a valid JSON object with this exact structure, nothing else:
{
  "rewardName": "Name of the item",
  "xpReward": 150,
  "motivation": "A short message here."
}
''';

    String text = '';

    if (provider == 'openrouter') {
      text = await _parseWithOpenRouter(prompt);
    } else {
      text = await _parseWithGemini(prompt);
    }

    if (text.isEmpty) {
      throw Exception('Gagal mendapatkan response dari AI');
    }

    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final jsonObj = jsonDecode(text) as Map<String, dynamic>;
      
      final rewardName = jsonObj['rewardName']?.toString() ?? '\$rarity Chest';
      final xpReward = (jsonObj['xpReward'] as num?)?.toInt() ?? minXp;
      final motivation = jsonObj['motivation']?.toString() ?? 'Keep up the good work!';

      return GachaReward(
        id: _uuid.v4(),
        rewardName: rewardName,
        dropRate: baseDropRate,
        xpReward: xpReward,
        rarity: rarity,
        motivation: motivation,
      );
    } catch (e) {
      throw Exception('Format JSON tidak sesuai: $e\nResponse: $text');
    }
  }

  /// Generates a Boss Profile (Name, Icon, Taunt) based on monthly expense
  static Future<Map<String, String>> generateBossProfile(String billName, double amount) async {
    final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini';

    final prompt = '''
You are a creative writer for an RPG-style habit tracker app.
The user has a monthly expense (bill) named "$billName" with the amount of $amount.
Transform this mundane monthly bill into a threatening RPG monster/boss.
Give the boss an epic name (e.g. if the bill is "Listrik", name it "The Voltage Vampire" or "Lord Electrus").
Choose a single suitable emoji for the boss (e.g. ⚡, 🧛, 👹).
Write a short taunt or threat (1 sentence) from the boss.

Output ONLY a valid JSON object with this exact structure, nothing else:
{
  "bossName": "Epic Boss Name",
  "bossIcon": "🧛",
  "bossTaunt": "Short threat message!"
}
''';

    String text = '';

    if (provider == 'openrouter') {
      text = await _parseWithOpenRouter(prompt);
    } else {
      text = await _parseWithGemini(prompt);
    }

    if (text.isEmpty) {
      throw Exception('Gagal mendapatkan response dari AI');
    }

    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final jsonObj = jsonDecode(text) as Map<String, dynamic>;
      return {
        'bossName': jsonObj['bossName']?.toString() ?? 'Unknown Entity',
        'bossIcon': jsonObj['bossIcon']?.toString() ?? '👾',
        'bossTaunt': jsonObj['bossTaunt']?.toString() ?? 'Pay me or else!',
      };
    } catch (e) {
      throw Exception('Format JSON tidak sesuai: $e\nResponse: $text');
    }
  }
}
