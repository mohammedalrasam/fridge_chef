import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/recipe_response.dart';

/// خدمة مسؤولة عن الاتصال بـ Gemini عبر Puter.js داخل WebView.
/// تعمل هذه الخدمة عن طريق تحميل صفحة HTML تحتوي على مكتبة Puter.js،
/// ثم تمرير الصورة بصيغة base64 إليها واستقبال النتيجة.
class PuterAiService {
  late WebViewController _controller;
  final Completer<RecipeResponse> _completer = Completer<RecipeResponse>();

  /// يُنشئ WebView مخفيًا يحمّل صفحة HTML مع Puter.js.
  /// يجب استدعاء هذه الدالة قبل [analyzeImage].
  Future<Widget> buildWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'PuterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          // استقبال النتيجة من JavaScript
          final raw = message.message;
          if (!_completer.isCompleted) {
            _completer.complete(RecipeResponse.fromRaw(raw));
          }
        },
      )
      ..loadHtmlString(_buildHtmlPage());

    // WebView مخفي لأنه لا يُعرض للمستخدم
    return const SizedBox.shrink();
  }

  /// يحلل الصورة ويعيد الوجبة المقترحة.
  /// [imageFile] هي الصورة الملتقطة من الكاميرا.
  Future<RecipeResponse> analyzeImage(File imageFile) async {
    // قراءة الصورة وتحويلها إلى base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // إرسال الصورة إلى JavaScript عبر القناة
    await _controller.runJavaScript('''
      window.analyzeFoodImage("$base64Image");
    ''');

    // انتظار النتيجة من JavaScript (مع مهلة 60 ثانية)
    return _completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception('انتهت مهلة الاتصال بالذكاء الاصطناعي. حاول مرة أخرى.');
      },
    );
  }

  /// يبني صفحة HTML التي تستدعي Puter.js.
  /// يحتوي على دالة JavaScript باسم analyzeFoodImage تستقبل الصورة base64.
  String _buildHtmlPage() {
    return '''
<!DOCTYPE html>
<html dir="rtl">
<head>
  <meta charset="UTF-8">
  <script src="https://js.puter.com/v2/"></script>
</head>
<body>
  <script>
    // دالة تُستدعى من فلاتر مع الصورة base64
    window.analyzeFoodImage = function(base64Image) {
      // بناء data URI لتضمين نوع الصورة
      var imageDataUri = "data:image/jpeg;base64," + base64Image;

      // تعليمات واضحة للنموذج لضمان استجابة منظمة
      var prompt = `أنت خبير طهي. حلل هذه الصورة لمحتويات ثلاجة.
      1. استخرج قائمة بجميع المكونات الغذائية الظاهرة.
      2. اقترح وصفة كاملة باستخدام هذه المكونات.
      أجب بالتنسيق التالي بالضبط:
      المكونات:
      - مكون 1
      - مكون 2
      الوصفة:
      خطوات التحضير هنا...`;

      // استدعاء Gemini عبر Puter.js مع الصورة والتعليمات
      puter.ai.chat(prompt, imageDataUri, {
        model: "google/gemini-3.8-flash"
      })
      .then(function(response) {
        // استخراج النص من الاستجابة
        var text = response.message.content[0].text;
        // إرسال النتيجة إلى فلاتر
        PuterBridge.postMessage(text);
      })
      .catch(function(error) {
        PuterBridge.postMessage("حدث خطأ: " + error.message);
      });
    };
  </script>
</body>
</html>
''';
  }
}