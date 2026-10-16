/// نموذج يمثل استجابة الذكاء الاصطناعي التي تحتوي على
/// قائمة المكونات والوصفة المقترحة.
class RecipeResponse {
  final List<String> ingredients;
  final String recipe;
  final String rawResponse;

  RecipeResponse({
    required this.ingredients,
    required this.recipe,
    required this.rawResponse,
  });

  /// يحاول استخراج المكونات والوصفة من النص المُعاد.
  /// إذا فشل التحليل، يتم وضع النص كاملاً في حقل الوصفة.
  factory RecipeResponse.fromRaw(String raw) {
    final lines = raw.split('\n');
    final ingredients = <String>[];
    final recipeLines = <String>[];
    bool inIngredients = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // اكتشاف بداية قسم المكونات (يدعم العربية والإنجليزية)
      if (trimmed.contains('مكونات') ||
          trimmed.contains('المكونات') ||
          trimmed.toLowerCase().contains('ingredients')) {
        inIngredients = true;
        continue;
      }

      // اكتشاف بداية قسم الوصفة
      if (trimmed.contains('وصفة') ||
          trimmed.contains('الوصفة') ||
          trimmed.toLowerCase().contains('recipe') ||
          trimmed.toLowerCase().contains('instructions')) {
        inIngredients = false;
        continue;
      }

      if (inIngredients) {
        // إزالة الشرطات والنقاط من بداية السطر
        final cleaned = trimmed.replaceFirst(RegExp(r'^[-•*\d.]+\s*'), '');
        if (cleaned.isNotEmpty) ingredients.add(cleaned);
      } else {
        recipeLines.add(trimmed);
      }
    }

    return RecipeResponse(
      ingredients: ingredients,
      recipe: recipeLines.join('\n'),
      rawResponse: raw,
    );
  }
}