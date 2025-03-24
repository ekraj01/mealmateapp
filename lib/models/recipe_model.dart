class Recipe {
  final String id;
  final String name;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<Ingredient> ingredients;
  final String instructions;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'ingredients': ingredients.map((ingredient) => {
        'name': ingredient.name,
        'quantity': ingredient.quantity,
        'unit': ingredient.unit,
        'category': ingredient.category,
      }).toList(),
      'instructions': instructions,
      'imageUrl': imageUrl,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      name: map['name'] as String,
      prepTime: map['prepTime'] as int? ?? 0,
      cookTime: map['cookTime'] as int? ?? 0,
      servings: map['servings'] as int? ?? 1,
      ingredients: (map['ingredients'] as List<dynamic>).map((item) {
        final ingredient = item as Map<String, dynamic>;
        return Ingredient(
          name: ingredient['name'] as String,
          quantity: (ingredient['quantity'] as num).toDouble(),
          unit: ingredient['unit'] as String,
          category: ingredient['category'] as String,
        );
      }).toList(),
      instructions: map['instructions'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

class Ingredient {
  final String name;
  final double quantity;
  final String unit;
  final String category;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
  });
}