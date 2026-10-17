import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../widgets/image_preview_card.dart';
import 'result_screen.dart';

/// الشاشة الرئيسية: التقاط صورة أو اختيارها من المعرض، ثم تحليلها.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _aiService = GeminiService();

  File? _selectedImage;
  bool _isAnalyzing = false;

  /// يلتقط صورة أو يختارها من المعرض.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85, // ضغط الصورة لتسريع الإرسال
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      _showError('فشل في التقاط الصورة: $e');
    }
  }

  /// يعرض خيارات تغيير الصورة عند الضغط عليها.
  Future<void> _changeImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة جديدة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// يحلل الصورة عبر Gemini ويعرض النتيجة.
  Future<void> _analyze() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _aiService.analyzeImage(_selectedImage!);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// يعرض رسالة خطأ في SnackBar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طباخ الثلاجة 🍳'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // منطقة معاينة الصورة
            Expanded(
              child: ImagePreviewCard(
                image: _selectedImage,
                onTap: _changeImage,
              ),
            ),
            const SizedBox(height: 20),

            // أزرار الكاميرا والمعرض
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.camera_alt,
                    label: 'الكاميرا',
                    color: Colors.blue,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    icon: Icons.photo_library,
                    label: 'المعرض',
                    color: Colors.purple,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // زر التحليل
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedImage == null || _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? 'جاري التحليل...' : 'اقترح وجبة 🍲',
                  style: const TextStyle(fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// داخل Widget build، أضف هذا الزر في أي مكان:
FloatingActionButton(
  onPressed: () async {
    try {
      final res = await GeminiService().testConnection();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ الاتصال ناجح: $res')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
      );
    }
  },
  child: const Icon(Icons.wifi_tethering),
),
  /// يبني زرًا مخصصًا للكاميرا والمعرض.
  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}