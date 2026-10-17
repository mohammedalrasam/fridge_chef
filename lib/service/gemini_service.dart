import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recipe_response.dart';

/// خدمة الاتصال المباشر بـ Google Gemini API عبر HTTP.
class GeminiService {
  // ⚠️ ضع مفتاحك هنا (احصل عليه من https://aistudio.google.com/app/apikey)
  static const String _apiKey = 'AQ.Ab8RN6LSSNrqpkcrQKINzKpqWhi1D6PHBoqzp0QugHE-0Wjgsw'
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const int _timeoutSeconds = 60;

  Future<RecipeResponse> analyzeImage(File imageFile) async {
    if (_apiKey.isEmpty || _apiKey.contains('ضع_مفتاح')) {
      throw Exception('مفتاح API غير مُعد. افتح ملف gemini_service.dart وضع مفتاحك.');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': _buildPrompt()},
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
      'systemInstruction': {
        'parts': [
          {
            'text': 'أنت شيف محترف متخصص في المطبخ العربي والمتوسطي. تجيب دائمًا بالعربية الفصحى الواضحة وبتنسيق منظم.',
          },
        ],
      },
    };

    final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));

      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال. تحقق من الإنترنت.');
    } on SocketException {
      throw Exception('لا يوجد اتصال بالإنترنت.');
    } on http.ClientException catch (e) {
      throw Exception('فشل الاتصال بالخادم: ${e.message}');
    }
  }

  RecipeResponse _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final text = _extractText(decoded);
      if (text.isEmpty) throw Exception('لم يُعد النموذج أي نص.');
      return RecipeResponse.fromRaw(text);
    }

    switch (response.statusCode) {
      case 400:
        throw Exception('طلب غير صالح. قد يكون المفتاح أو النموذج غير صحيح.\n$body');
      case 401:
      case 403:
        throw Exception('مفتاح API غير صالح أو منتهي.');
      case 404:
        throw Exception('النموذج "$_model" غير موجود.');
      case 429:
        throw Exception('تجاوزت الحد المجاني. انتظر دقيقة ثم حاول مجددًا.');
      case 500:
      case 502:
      case 503:
        throw Exception('خطأ في خوادم Google. حاول بعد قليل.');
      default:
        throw Exception('فشل الاتصال بـ Gemini (${response.statusCode}).\n$body');
    }
  }

  String _extractText(Map<String, dynamic> decoded) {
    try {
      if (decoded['error'] != null) {
        throw Exception('خطأ من Gemini: ${decoded['error']['message']}');
      }

      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';

      final content = candidates[0]['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';

      final buffer = StringBuffer();
      for (final part in parts) {
        final text = part['text'];
        if (text is String && text.isNotEmpty) buffer.write(text);
      }
      return buffer.toString().trim();
    } catch (e) {
      if (e is Exception) rethrow;
      return '';
    }
  }

  String _buildPrompt() {
    return '''أنت خبير طهي. حلل هذه الصورة لمحتويات ثلاجة المنزل.
1. تعرّف على جميع المكونات الغذائية الظاهرة في الصورة.
2. اقترح وصفة واحدة كاملة يمكن تحضيرها باستخدام معظم هذه المكونات.

أجب بالتنسيق التالي بالضبط دون أي إضافات أو مقدمات:

المكونات:
- مكون 1
- مكون 2
- مكون 3

الوصفة:
اسم الطبق: [اسم الطبق]

المقادير:
- مقدر 1
- مقدر 2

خطوات التحضير:
1. الخطوة الأولى...
2. الخطوة الثانية...
3. الخطوة الثالثة...

نصيحة: [نصيحة قصيرة لتحسين الطبق]''';
  }
}
