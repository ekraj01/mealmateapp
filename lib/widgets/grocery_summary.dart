import 'package:flutter/material.dart';
import '../models/grocery_list_model.dart';

class GrocerySummary extends StatelessWidget {
  final GroceryList groceryList; // Change to single GroceryList

  const GrocerySummary({super.key, required this.groceryList}); // Update constructor

  @override
  Widget build(BuildContext context) {
    final totalItems = groceryList.items.length; // Use the single list’s items
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groceryList.name, // Show the list’s name instead of a generic title
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total Items: $totalItems'),
          ],
        ),
      ),
    );
  }
}