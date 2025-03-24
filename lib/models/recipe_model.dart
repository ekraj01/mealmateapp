import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

class Ingredient {
  final String name;
  final double quantity;
  final String? unit;
  final String? category;

  Ingredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String?,
      category: map['category'] as String?,
    );
  }
}

class Recipe {
  final String? id;
  final String? name;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<Ingredient> ingredients;
  final String instructions;
  final String? imageUrl;
  final DateTime createdAt;

  Recipe({
    this.id,
    this.name,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'instructions': instructions,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String?,
      name: map['name'] as String?,
      prepTime: map['prepTime'] as int? ?? 0,
      cookTime: map['cookTime'] as int? ?? 0,
      servings: map['servings'] as int? ?? 1,
      ingredients: (map['ingredients'] as List? ?? [])
          .map((i) => Ingredient.fromMap(i as Map<String, dynamic>))
          .toList(),
      instructions: map['instructions'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    int? prepTime,
    int? cookTime,
    int? servings,
    List<Ingredient>? ingredients,
    String? instructions,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}