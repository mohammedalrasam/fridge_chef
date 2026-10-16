import 'dart:async';         // ✅ الإصلاح: مطلوب لاستخدام Completer
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/recipe_response.dart';

/// خدمة مسؤولة عن الاتصال بـ Gemini عبر Puter.js داخل WebView.
///
/// مهم: يجب إدراج الويدجت الذي تعيده [buildWebViewWidget] داخل شجرة الواجهة
/// (حتى لو كان بحجم صفر) حتى يعمل JavaScript فعليًا.
class PuterAiService {
  WebViewController? _controller;
  Completer<RecipeResponse>? _completer;
  bool _isPageReady = false;

  /// ينشئ ويدجت WebView يحتوي على صفحة HTML مع Puter.js.
  /// يجب وضع هذا الويدجت داخل شجرة الواجهة (انظر home_screen).
  Widget buildWebViewWidget() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'PuterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          final raw = message.message;
          final completer = _completer;
          if (completer != null && !completer.isCompleted) {
            completer.complete(RecipeResponse.fromRaw(raw));
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _isPageReady = true;
          },
        ),
      )
      ..loadHtmlString(_buildHtmlPage());

    return WebViewWidget(controller: _controller!);
  }

  /// يحلل الصورة ويعيد الوصفة المقترحة.
  Future<RecipeResponse> analyzeImage(File imageFile) async {
    if (_controller == null) {
      throw Exception('لم يتم تهيئة WebView بعد.');
    }

    // انتظار قصير حتى تكتمل تهيئة الصفحة ومكتبة Puter.js.
    // (يمكن تحسينها لاحقًا بربط onPageFinished مع Completer).
    int waited = 0;
    while (!_isPageReady && waited < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      waited++;
    }
    // مهلة إضافية بسيطة لتحميل puter.js من CDN.
    await Future.delayed(const Duration(milliseconds: 800));

    // قراءة الصورة وتحويلها إلى base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // إنشاء Completer جديد لكل طلب
    _completer = Completer<RecipeResponse>();

    // إرسال الصورة إلى JavaScript
    await _controller!.runJavaScript(
      'window.analyzeFoodImage("$base64Image");',
    );

    // انتظار النتيجة (مهلة 60 ثانية)
    return _completer!.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw Exception(
          'انتهت مهلة الاتصال بالذكاء الاصطناعي. تحقق من الإنترنت وحاول مجددًا.',
        );
      },
    );
  }

  /// يبني صفحة HTML التي تستدعي Puter.js.
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
    window.analyzeFoodImage = function(base64Image) {
      try {
        var imageDataUri = "data:image/jpeg;base64," + base64Image;

        var prompt = `أنت خبير طهي. حلل هذه الصورة لمحتويات ثلاجة.
1. استخرج قائمة بجميع المكونات الغذائية الظاهرة.
2. اقترح وصفة كاملة باستخدام هذه المكونات.
أجب بالتنسيق التالي بالضبط:
المكونات:
- مكون 1
- مكون 2
الوصفة:
خطوات التحضير هنا...`;

        puter.ai.chat(prompt, imageDataUri, {
          model: "google/gemini-2.5-flash"
        })
        .then(function(response) {
          var text = "";
          if (response && response.message && response.message.content) {
            var content = response.message.content;
            if (Array.isArray(content)) {
              text = content.map(function(c){ return c.text || ""; }).join("\\n");
            } else if (typeof content === "string") {
              text = content;
            }
          } else if (typeof response === "string") {
            text = response;
          }
          PuterBridge.postMessage(text || "لم يتم استلام رد من النموذج.");
        })
        .catch(function(error) {
          PuterBridge.postMessage("حدث خطأ: " + (error && error.message ? error.message : error));
        });
      } catch (e) {
        PuterBridge.postMessage("خطأ في JavaScript: " + e.message);
      }
    };
  </script>
</body>
</html>
''';
  }
}