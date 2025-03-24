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
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _unit = 'pcs';
  String _category = 'Other';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.ingredient['name'] as String;
    _quantityController.text = (widget.ingredient['quantity'] as double).toString();
    _unit = widget.ingredient['unit'] as String;
    _category = widget.ingredient['category'] as String;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _updateIngredient() {
    widget.onUpdate({
      'name': _nameController.text,
      'quantity': double.tryParse(_quantityController.text) ?? 1.0,
      'unit': _unit,
      'category': _category,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateIngredient(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: ['pcs', 'kg', 'g', 'ml', 'l', 'tbsp', 'tsp']
                        .map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _unit = value!;
                        _updateIngredient();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Vegetables', 'Proteins', 'Grains', 'Other']
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                  _updateIngredient();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}