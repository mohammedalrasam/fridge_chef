import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recipe_response.dart';

/// خدمة الاتصال المباشر بـ Gemini API عبر HTTP.
/// لا تحتاج WebView ولا Puter.js — تعمل مباشرة من Dart.
class GeminiService {
  /// ⚠️ ضع مفتاحك هنا. الأفضل وضعه في متغير بيئة أو ملف .env.
  static const String _apiKey = String.fromEvironment('AQ.Ab8RN6LSSNrqpkcrQKINzKpqWhi1D6PHBoqzp0QugHE-0Wjgsw',defaultvalue:'',);

  /// اسم النموذج. gemini-2.0-flash لديه أفضل طبقة مجانية (1500 طلب/يوم).
  static const String _model = 'gemini-2.0-flash';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// يحلل صورة الطعام ويعيد المكونات والوصفة.
  Future<RecipeResponse> analyzeImage(File imageFile) async {
    // 1. قراءة الصورة وتحويلها إلى base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 2. بناء جسم الطلب بصيغة Gemini API
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': _buildPrompt(),
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2048,
      },
    };

    // 3. إرسال الطلب
    final uri = Uri.parse('$_endpoint/$_model:generateContent?key=$_apiKey');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 60));

    // 4. معالجة الاستجابة
    if (response.statusCode != 200) {
      throw Exception(
        'فشل الاتصال بـ Gemini (${response.statusCode}):\n${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final text = _extractText(decoded);

    if (text.isEmpty) {
      throw Exception('لم يُعد النموذج أي نص. حاول مرة أخرى.');
    }

    return RecipeResponse.fromRaw(text);
  }

  /// يبني التعليمات المُرسلة للنموذج.
  String _buildPrompt() {
    return '''أنت خبير طهي محترف. حلل الصورة المرفقة لمحتويات ثلاجة المنزل.

المطلوب:
1. استخرج قائمة بجميع المكونات الغذائية الظاهرة في الصورة (بالعربية).
2. اقترح وصفة واحدة كاملة يمكن تحضيرها باستخدام هذه المكونات، مع خطوات واضحة.

أجب بهذا التنسيق بالضبط دون أي إضافات:

المكونات:
- مكون 1
- مكون 2
- مكون 3

الوصفة:
اسم الطبق: ...

المقادير المطلوبة:
...

خطوات التحضير:
1. ...
2. ...
3. ...

نصيحة: ...''';
  }

  /// يستخرج النص من استجابة Gemini.
  String _extractText(Map<String, dynamic> decoded) {
    try {
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';

      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';

      final buffer = StringBuffer();
      for (final part in parts) {
        final t = part['text'];
        if (t is String) buffer.writeln(t);
      }
      return buffer.toString().trim();
    } catch (_) {
      return '';
    }
  }
}
