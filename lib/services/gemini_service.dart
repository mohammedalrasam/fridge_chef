import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/recipe_response.dart';

class GeminiService {
  static const String _apiKey = 'AQ.Ab8RN6LSSNrqpkcrQKINzKpqWhi1D6PHBoqzp0QugHE-0Wjgsw'
  static const String _model = 'gemini-2.0-flash';

  Future<RecipeResponse> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': 'أنت خبير طهي. حلل الصورة واستخرج المكونات واقترح وصفة. أجب بهذا التنسيق: \nالمكونات:\n- مكون 1\nالوصفة:\nخطوات التحضير...'},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              },
            },
          ],
        },
      ],
    };

    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;
      return RecipeResponse.fromRaw(text);
    } else {
      throw Exception('فشل الاتصال (${response.statusCode}): ${response.body}');
    }
  }
}
