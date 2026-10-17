class RecipeResponse {
  final List<String> ingredients;
  final String recipe;
  final String rawResponse;

  RecipeResponse({
    required this.ingredients,
    required this.recipe,
    required this.rawResponse,
  });

  factory RecipeResponse.fromRaw(String raw) {
    final lines = raw.split('\n');
    final ingredients = <String>[];
    final recipeLines = <String>[];
    bool inIngredients = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.contains('مكونات') || trimmed.contains('المكونات') || trimmed.toLowerCase().contains('ingredients')) {
        inIngredients = true;
        continue;
      }
      if (trimmed.contains('وصفة') || trimmed.contains('الوصفة') || trimmed.toLowerCase().contains('recipe')) {
        inIngredients = false;
        continue;
      }
      if (inIngredients) {
        final cleaned = trimmed.replaceFirst(RegExp(r'^[-•*\d.]+\s*'), '');
        if (cleaned.isNotEmpty) ingredients.add(cleaned);
      } else {
        recipeLines.add(trimmed);
      }
    }
    return RecipeResponse(ingredients: ingredients, recipe: recipeLines.join('\n'), rawResponse: raw);
  }
}
