import 'package:flutter/material.dart';
import '../models/grocery_list_model.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.purchased,
        onChanged: (value) => onToggle(value!),
      ),
      title: Text(item.name ?? 'Unknown Item'),
      subtitle: Text('${item.quantity ?? 0} ${item.unit ?? ''}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}