import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/grocery_list_model.dart';
import '../models/recipe_model.dart';

class GroceryProvider with ChangeNotifier {
  final DatabaseReference _groceryListsRef = FirebaseDatabase.instance.ref('groceryLists');
  final List<GroceryItem> _purchasedItems = [];
  final List<GroceryItem> _deletedItems = [];
  List<GroceryList> _groceryLists = [];
  final Map<String, List<GroceryItem>> _categorizedItems = {
    'Vegetables': [],
    'Proteins': [],
    'Grains': [],
  };

  List<GroceryList> get groceryLists => _groceryLists;
  Map<String, List<GroceryItem>> get categorizedItems => _categorizedItems;
  List<GroceryItem> get purchasedItems => _purchasedItems;
  List<GroceryItem> get deletedItems => _deletedItems;

  Future<void> fetchGroceryLists() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      final snapshot = await _groceryListsRef.child(userId).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

      _groceryLists = [];
      if (data != null) {
        _groceryLists = data.entries.map((entry) {
          final listData = entry.value as Map<dynamic, dynamic>;
          return GroceryList(
            id: entry.key,
            name: listData['name'] as String,
            items: (listData['items'] as List<dynamic>? ?? []).asMap().entries.map((itemEntry) {
              final item = itemEntry.value as Map<dynamic, dynamic>;
              return GroceryItem(
                id: item['id'] as String,
                name: item['name'] as String,
                category: item['category'] as String,
                quantity: (item['quantity'] as num).toDouble(),
                unit: item['unit'] as String,
                purchased: item['purchased'] as bool? ?? false,
                purchasedAt: (item['purchasedAt'] as int?) != null
                    ? DateTime.fromMillisecondsSinceEpoch(item['purchasedAt'] as int)
                    : null,
                deletedAt: (item['deletedAt'] as int?) != null
                    ? DateTime.fromMillisecondsSinceEpoch(item['deletedAt'] as int)
                    : null,
              );
            }).toList(),
            recipes: (listData['recipes'] as List<dynamic>? ?? [])
                .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
                .toList(),
            createdAt: (listData['createdAt'] as int?) != null
                ? DateTime.fromMillisecondsSinceEpoch(listData['createdAt'] as int)
                : DateTime.now(),
          );
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch grocery lists: $e');
    }
  }

  Future<GroceryList> getGroceryList(String id) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      final snapshot = await _groceryListsRef.child(userId).child(id).once();
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) throw Exception('Grocery list not found');
      return GroceryList(
        id: id,
        name: data['name'] as String,
        items: (data['items'] as List<dynamic>? ?? []).asMap().entries.map((itemEntry) {
          final item = itemEntry.value as Map<dynamic, dynamic>;
          return GroceryItem(
            id: item['id'] as String,
            name: item['name'] as String,
            category: item['category'] as String,
            quantity: (item['quantity'] as num).toDouble(),
            unit: item['unit'] as String,
            purchased: item['purchased'] as bool? ?? false,
            purchasedAt: (item['purchasedAt'] as int?) != null
                ? DateTime.fromMillisecondsSinceEpoch(item['purchasedAt'] as int)
                : null,
            deletedAt: (item['deletedAt'] as int?) != null
                ? DateTime.fromMillisecondsSinceEpoch(item['deletedAt'] as int)
                : null,
          );
        }).toList(),
        recipes: (data['recipes'] as List<dynamic>? ?? [])
            .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
            .toList(),
        createdAt: (data['createdAt'] as int?) != null
            ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
            : DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get grocery list: $e');
    }
  }

  Future<void> addGroceryList(GroceryList list) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      final userGroceryListRef = _groceryListsRef.child(userId).child(list.id);
      await userGroceryListRef.set({
        'userId': userId,
        'name': list.name,
        'items': list.items.map((item) => {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity,
          'unit': item.unit,
          'purchased': item.purchased,
          'purchasedAt': item.purchasedAt?.millisecondsSinceEpoch,
          'deletedAt': item.deletedAt?.millisecondsSinceEpoch,
        }).toList(),
        'recipes': list.recipes.map((recipe) => recipe.toMap()).toList(), // Null check not needed since recipes are non-nullable
        'createdAt': list.createdAt.millisecondsSinceEpoch,
      });
      _groceryLists.add(list);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add grocery list: $e');
    }
  }

  Future<void> updateGroceryList(GroceryList list) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      await _groceryListsRef.child(userId).child(list.id).update({
        'name': list.name,
        'items': list.items.map((item) => {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity,
          'unit': item.unit,
          'purchased': item.purchased,
          'purchasedAt': item.purchasedAt?.millisecondsSinceEpoch,
          'deletedAt': item.deletedAt?.millisecondsSinceEpoch,
        }).toList(),
        'recipes': list.recipes.map((recipe) => recipe.toMap()).toList(), // Null check not needed since recipes are non-nullable
        'createdAt': list.createdAt.millisecondsSinceEpoch,
      });
      final index = _groceryLists.indexWhere((l) => l.id == list.id);
      if (index != -1) {
        _groceryLists[index] = list;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update grocery list: $e');
    }
  }

  Future<void> deleteGroceryList(String id) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      await _groceryListsRef.child(userId).child(id).remove();
      _groceryLists.removeWhere((list) => list.id == id);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete grocery list: $e');
    }
  }

  void compileIngredientsFromRecipes(List<Recipe> recipes) {
    _categorizedItems.clear();
    _categorizedItems['Vegetables'] = [];
    _categorizedItems['Proteins'] = [];
    _categorizedItems['Grains'] = [];
    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final groceryItem = GroceryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: ingredient.name,
          category: ingredient.category,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
        );
        if (ingredient.category.toLowerCase() == 'vegetables' ||
            ingredient.name.toLowerCase().contains('carrot') ||
            ingredient.name.toLowerCase().contains('broccoli')) {
          _categorizedItems['Vegetables']!.add(groceryItem);
        } else if (ingredient.category.toLowerCase() == 'proteins' ||
            ingredient.name.toLowerCase().contains('chicken') ||
            ingredient.name.toLowerCase().contains('beef')) {
          _categorizedItems['Proteins']!.add(groceryItem);
        } else if (ingredient.category.toLowerCase() == 'grains' ||
            ingredient.name.toLowerCase().contains('rice') ||
            ingredient.name.toLowerCase().contains('pasta')) {
          _categorizedItems['Grains']!.add(groceryItem);
        } else {
          _categorizedItems['Vegetables']!.add(groceryItem);
        }
      }
    }
    notifyListeners();
  }

  void clearPurchasedAndDeletedItems() {
    _purchasedItems.clear();
    _deletedItems.clear();
    notifyListeners();
  }

  void addPurchasedItem(GroceryItem item) {
    _purchasedItems.add(item.copyWith(
      purchasedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void addDeletedItem(GroceryItem item) {
    _deletedItems.add(item.copyWith(
      deletedAt: DateTime.now(),
    ));
    notifyListeners();
  }
}