import 'package:flutter/material.dart';

class IngredientInput extends StatefulWidget {
  final Map<String, dynamic> ingredient;
  final Function(Map<String, dynamic>) onUpdate;
  final VoidCallback onDelete;

  const IngredientInput({
    super.key,
    required this.ingredient,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  _IngredientInputState createState() => _IngredientInputState();
}

class _IngredientInputState extends State<IngredientInput> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ingredient['name']);
    _quantityController = TextEditingController(text: widget.ingredient['quantity'].toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.onUpdate({
                  'name': value,
                  'quantity': double.tryParse(_quantityController.text) ?? 1.0,
                  'unit': widget.ingredient['unit'],
                  'category': widget.ingredient['category'],
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Qty',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                widget.onUpdate({
                  'name': _nameController.text,
                  'quantity': double.tryParse(value) ?? 1.0,
                  'unit': widget.ingredient['unit'],
                  'category': widget.ingredient['category'],
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}