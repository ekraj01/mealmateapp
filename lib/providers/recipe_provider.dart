import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/recipe_model.dart';

class RecipeProvider with ChangeNotifier {
  final DatabaseReference _recipesRef = FirebaseDatabase.instance.ref('recipes');
  List<Recipe> _recipes = [];

  List<Recipe> get recipes => _recipes;

  /// Fetches all recipes for the current user from Firebase Realtime Database.
  Future<void> fetchRecipes() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final snapshot = await _recipesRef.child(userId).once();
      final data = snapshot.snapshot.value;

      _recipes = [];
      if (data != null) {
        // Convert LinkedMap<Object?, Object?> to Map<String, dynamic>
        final Map<String, dynamic> recipesMap = (data as Map).map((key, value) {
          return MapEntry(key.toString(), value as Map);
        });

        _recipes = recipesMap.entries.map((entry) {
          final recipeData = entry.value as Map<String, dynamic>;
          return Recipe(
            id: entry.key,
            name: recipeData['name'] as String,
            prepTime: recipeData['prepTime'] as int? ?? 0,
            cookTime: recipeData['cookTime'] as int? ?? 0,
            servings: recipeData['servings'] as int? ?? 1,
            ingredients: (recipeData['ingredients'] as List<dynamic>).map((item) {
              final ingredient = item as Map<String, dynamic>;
              return Ingredient(
                name: ingredient['name'] as String,
                quantity: (ingredient['quantity'] as num).toDouble(),
                unit: ingredient['unit'] as String,
                category: ingredient['category'] as String,
              );
            }).toList(),
            instructions: recipeData['instructions'] as String? ?? '',
            imageUrl: recipeData['imageUrl'] as String?,
          );
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Retrieves a single recipe by its ID.
  Future<Recipe> getRecipe(String id) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final snapshot = await _recipesRef.child(userId).child(id).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) throw Exception('Recipe not found');

      return Recipe(
        id: id,
        name: data['name'] as String,
        prepTime: data['prepTime'] as int? ?? 0,
        cookTime: data['cookTime'] as int? ?? 0,
        servings: data['servings'] as int? ?? 1,
        ingredients: (data['ingredients'] as List<dynamic>).map((item) {
          final ingredient = item as Map<String, dynamic>;
          return Ingredient(
            name: ingredient['name'] as String,
            quantity: (ingredient['quantity'] as num).toDouble(),
            unit: ingredient['unit'] as String,
            category: ingredient['category'] as String,
          );
        }).toList(),
        instructions: data['instructions'] as String? ?? '',
        imageUrl: data['imageUrl'] as String?,
      );
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }

  /// Adds a new recipe to Firebase.
  Future<void> addRecipe(Recipe recipe) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final userRecipeRef = _recipesRef.child(userId).child(recipe.id);
      await userRecipeRef.set({
        'name': recipe.name,
        'prepTime': recipe.prepTime,
        'cookTime': recipe.cookTime,
        'servings': recipe.servings,
        'ingredients': recipe.ingredients.map((ingredient) => {
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'category': ingredient.category,
        }).toList(),
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
      });

      _recipes.add(recipe);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }

  /// Updates an existing recipe in Firebase.
  Future<void> updateRecipe(Recipe recipe) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _recipesRef.child(userId).child(recipe.id).update({
        'name': recipe.name,
        'prepTime': recipe.prepTime,
        'cookTime': recipe.cookTime,
        'servings': recipe.servings,
        'ingredients': recipe.ingredients.map((ingredient) => {
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'category': ingredient.category,
        }).toList(),
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
      });

      final index = _recipes.indexWhere((r) => r.id == recipe.id);
      if (index != -1) {
        _recipes[index] = recipe;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  /// Deletes a recipe from Firebase.
  Future<void> deleteRecipe(String id) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _recipesRef.child(userId).child(id).remove();
      _recipes.removeWhere((recipe) => recipe.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }
}