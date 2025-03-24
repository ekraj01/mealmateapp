import 'package:flutter/material.dart';
import '../models/grocery_list_model.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final Function(bool) onPurchased;
  final VoidCallback onDelete;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onPurchased,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onPurchased(!item.purchased);
        } else {
          onDelete();
        }
      },
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: item.purchased,
            onChanged: (value) {
              onPurchased(value!);
            },
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.purchased ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text('${item.quantity} ${item.unit} (${item.category})'),
        ),
      ),
    );
  }
}