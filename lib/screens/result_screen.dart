import 'package:flutter/material.dart';
import '../models/recipe_response.dart';

/// شاشة عرض النتيجة: المكونات والوصفة المقترحة.
class ResultScreen extends StatelessWidget {
  final RecipeResponse result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الوجبة المقترحة 🍲'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم المكونات
            if (result.ingredients.isNotEmpty) ...[
              _sectionCard(
                title: 'المكونات المكتشفة',
                icon: Icons.kitchen,
                color: Colors.orange,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.ingredients
                      .map((ing) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(ing,
                                        style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // قسم الوصفة
            _sectionCard(
              title: 'الوصفة المقترحة',
              icon: Icons.restaurant_menu,
              color: Colors.green,
              child: Text(
                result.recipe.isNotEmpty
                    ? result.recipe
                    : result.rawResponse,
                style: const TextStyle(fontSize: 16, height: 1.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}