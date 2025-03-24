import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/grocery_list_model.dart';
import '../models/recipe_model.dart';
import '../providers/grocery_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/custom_button.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _editingListId;
  GroceryList? _groceryList;
  List<Recipe> _selectedRecipes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listId = ModalRoute.of(context)!.settings.arguments as String;
      if (listId != 'new') {
        _editingListId = listId;
        _loadGroceryList(listId);
      }
    });
  }

  Future<void> _loadGroceryList(String listId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
      _groceryList = await groceryProvider.getGroceryList(listId);
      _nameController.text = _groceryList!.name;
      _selectedRecipes = _groceryList!.recipes;
      groceryProvider.compileIngredientsFromRecipes(_selectedRecipes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grocery list: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveGroceryList() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
      final listId = _editingListId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final groceryList = GroceryList(
        id: listId,
        name: _nameController.text,
        items: _groceryList?.items ?? [],
        recipes: _selectedRecipes,
        createdAt: _groceryList?.createdAt ?? DateTime.now(),
      );

      if (_editingListId != null) {
        await groceryProvider.updateGroceryList(groceryList);
      } else {
        await groceryProvider.addGroceryList(groceryList);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grocery list: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareGroceryList() {
    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    final categorizedItems = groceryProvider.categorizedItems;
    final buffer = StringBuffer();
    buffer.writeln('Grocery List: ${_nameController.text}');
    buffer.writeln('Items:');
    categorizedItems.forEach((category, items) {
      buffer.writeln('$category:');
      for (final item in items) {
        buffer.writeln('- ${item.name} (${item.quantity} ${item.unit})');
      }
    });
    buffer.writeln('Store: Local Supermarket');
    buffer.writeln('Estimated Price: \$50');
    Share.share(buffer.toString(), subject: 'Grocery List');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final recipes = recipeProvider.recipes;
    final categorizedItems = groceryProvider.categorizedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingListId == null ? 'Create Grocery List' : 'Edit Grocery List'),
        actions: [
          if (_editingListId != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareGroceryList,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Recipes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            recipes.isEmpty
                ? const Center(child: Text('No recipes available'))
                : Wrap(
              spacing: 8,
              children: recipes.map((recipe) {
                final isSelected = _selectedRecipes.contains(recipe);
                return FilterChip(
                  label: Text(recipe.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRecipes.add(recipe);
                      } else {
                        _selectedRecipes.remove(recipe);
                      }
                      groceryProvider.compileIngredientsFromRecipes(_selectedRecipes);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (categorizedItems.isEmpty)
              const Center(child: Text('No items yet'))
            else
              ...categorizedItems.entries.map((entry) {
                final category = entry.key;
                final items = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.asMap().entries.map((itemEntry) {
                      final index = itemEntry.key;
                      final item = itemEntry.value;
                      return GroceryItemTile(
                        item: item,
                        onPurchased: (purchased) {
                          final updatedItem = item.copyWith(
                            purchased: purchased,
                            purchasedAt: purchased ? DateTime.now() : null,
                          );
                          groceryProvider.addPurchasedItem(updatedItem);
                          if (_groceryList != null) {
                            _groceryList!.items[index] = updatedItem;
                            groceryProvider.updateGroceryList(_groceryList!);
                          }
                        },
                        onDelete: () {
                          groceryProvider.addDeletedItem(item);
                          if (_groceryList != null) {
                            _groceryList!.items.removeAt(index);
                            groceryProvider.updateGroceryList(_groceryList!);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Save List',
              isLoading: _isLoading,
              onPressed: _saveGroceryList,
            ),
          ],
        ),
      ),
    );
  }
}