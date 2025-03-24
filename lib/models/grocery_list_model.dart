import 'package:mealmateapp/models/recipe_model.dart'; // Import Recipe

class GroceryItem {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final bool purchased;
  final DateTime? purchasedAt;
  final DateTime? deletedAt;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.purchased = false,
    this.purchasedAt,
    this.deletedAt,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    bool? purchased,
    DateTime? purchasedAt,
    DateTime? deletedAt,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchased: purchased ?? this.purchased,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class GroceryList {
  final String id;
  final String name;
  final List<GroceryItem> items;
  final List<Recipe> recipes; // Line 50: Now recognized
  final DateTime createdAt;

  GroceryList({
    required this.id,
    required this.name,
    required this.items,
    required this.recipes,
    required this.createdAt,
  });
}