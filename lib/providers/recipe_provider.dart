import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe_model.dart';

class RecipeProvider with ChangeNotifier {
  final CollectionReference _recipesCollection =
  FirebaseFirestore.instance.collection('recipes');
  List<Recipe> _recipes = [];

  List<Recipe> get recipes => _recipes;

  Future<void> fetchRecipes() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      QuerySnapshot snapshot = await _recipesCollection
          .where('userId', isEqualTo: userId)
          .get();
      _recipes = snapshot.docs.map((doc) {
        return Recipe.fromMap(doc.data() as Map<String, dynamic>)
            .copyWith(id: doc.id);
      }).toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  Future<Recipe> getRecipe(String id) async {
    try {
      DocumentSnapshot doc = await _recipesCollection.doc(id).get();
      if (!doc.exists) throw Exception('Recipe not found');
      return Recipe.fromMap(doc.data() as Map<String, dynamic>).copyWith(id: doc.id);
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      DocumentReference docRef = await _recipesCollection.add({
        'userId': userId,
        'name': recipe.name,
        'prepTime': recipe.prepTime,
        'cookTime': recipe.cookTime,
        'servings': recipe.servings,
        'ingredients': recipe.ingredients.map((i) => i.toMap()).toList(),
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
        'createdAt': Timestamp.fromDate(recipe.createdAt),
      });
      _recipes.add(recipe.copyWith(id: docRef.id));
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add recipe: $e');
    }
  }

  Future<void> updateRecipe(Recipe recipe) async {
    try {
      await _recipesCollection.doc(recipe.id).update({
        'name': recipe.name,
        'prepTime': recipe.prepTime,
        'cookTime': recipe.cookTime,
        'servings': recipe.servings,
        'ingredients': recipe.ingredients.map((i) => i.toMap()).toList(),
        'instructions': recipe.instructions,
        'imageUrl': recipe.imageUrl,
        'createdAt': Timestamp.fromDate(recipe.createdAt),
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

  Future<void> deleteRecipe(String id) async {
    try {
      await _recipesCollection.doc(id).delete();
      _recipes.removeWhere((recipe) => recipe.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }
}