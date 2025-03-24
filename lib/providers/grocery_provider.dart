import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/grocery_list_model.dart';
import '../models/recipe_model.dart';

class GroceryProvider with ChangeNotifier {
  final CollectionReference _groceryListsCollection =
  FirebaseFirestore.instance.collection('groceryLists');
  List<GroceryItem> _purchasedItems = [];
  List<GroceryItem> _deletedItems = [];
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
      QuerySnapshot snapshot = await _groceryListsCollection
          .where('userId', isEqualTo: userId)
          .get();
      _groceryLists = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GroceryList(
          id: doc.id,
          name: data['name'] as String,
          items: (data['items'] as List? ?? [])
              .map((item) => GroceryItem(
            id: item['id'] as String,
            name: item['name'] as String? ?? 'Unknown Item',
            category: item['category'] as String? ?? 'Other',
            quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
            unit: item['unit'] as String? ?? '',
            purchased: item['purchased'] as bool? ?? false,
            purchasedAt: (item['purchasedAt'] as Timestamp?)?.toDate(),
            deletedAt: (item['deletedAt'] as Timestamp?)?.toDate(),
          ))
              .toList(),
          recipes: (data['recipes'] as List? ?? [])
              .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
              .toList(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch grocery lists: $e');
    }
  }

  Future<GroceryList> getGroceryList(String id) async {
    try {
      DocumentSnapshot doc = await _groceryListsCollection.doc(id).get();
      if (!doc.exists) throw Exception('Grocery list not found');
      final data = doc.data() as Map<String, dynamic>;
      return GroceryList(
        id: doc.id,
        name: data['name'] as String,
        items: (data['items'] as List? ?? [])
            .map((item) => GroceryItem(
          id: item['id'] as String,
          name: item['name'] as String? ?? 'Unknown Item',
          category: item['category'] as String? ?? 'Other',
          quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
          unit: item['unit'] as String? ?? '',
          purchased: item['purchased'] as bool? ?? false,
          purchasedAt: (item['purchasedAt'] as Timestamp?)?.toDate(),
          deletedAt: (item['deletedAt'] as Timestamp?)?.toDate(),
        ))
            .toList(),
        recipes: (data['recipes'] as List? ?? [])
            .map((recipe) => Recipe.fromMap(recipe as Map<String, dynamic>))
            .toList(),
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get grocery list: $e');
    }
  }

  Future<void> addGroceryList(GroceryList list) async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      await _groceryListsCollection.doc(list.id).set({
        'userId': userId,
        'name': list.name,
        'items': list.items.map((item) => {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity,
          'unit': item.unit,
          'purchased': item.purchased,
          'purchasedAt': item.purchasedAt,
          'deletedAt': item.deletedAt,
        }).toList(),
        'recipes': list.recipes.map((recipe) => recipe.toMap()).toList(),
        'createdAt': Timestamp.fromDate(list.createdAt),
      });
      _groceryLists.add(list);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add grocery list: $e');
    }
  }

  Future<void> updateGroceryList(GroceryList list) async {
    try {
      await _groceryListsCollection.doc(list.id).update({
        'name': list.name,
        'items': list.items.map((item) => {
          'id': item.id,
          'name': item.name,
          'category': item.category,
          'quantity': item.quantity,
          'unit': item.unit,
          'purchased': item.purchased,
          'purchasedAt': item.purchasedAt,
          'deletedAt': item.deletedAt,
        }).toList(),
        'recipes': list.recipes.map((recipe) => recipe.toMap()).toList(),
        'createdAt': Timestamp.fromDate(list.createdAt),
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
      await _groceryListsCollection.doc(id).delete();
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
          name: ingredient.name ?? 'Unknown Item',
          category: ingredient.category ?? 'Other',
          quantity: ingredient.quantity ?? 0.0,
          unit: ingredient.unit ?? '',
        );

        if ((ingredient.category ?? '').toLowerCase() == 'vegetables' ||
            (ingredient.name ?? '').toLowerCase().contains('carrot') ||
            (ingredient.name ?? '').toLowerCase().contains('broccoli')) {
          _categorizedItems['Vegetables']!.add(groceryItem);
        } else if ((ingredient.category ?? '').toLowerCase() == 'proteins' ||
            (ingredient.name ?? '').toLowerCase().contains('chicken') ||
            (ingredient.name ?? '').toLowerCase().contains('beef')) {
          _categorizedItems['Proteins']!.add(groceryItem);
        } else if ((ingredient.category ?? '').toLowerCase() == 'grains' ||
            (ingredient.name ?? '').toLowerCase().contains('rice') ||
            (ingredient.name ?? '').toLowerCase().contains('pasta')) {
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
}