import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/grocery_list_model.dart';
import '../models/recipe_model.dart';
import '../providers/grocery_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/grocery_item_tile.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  GroceryListScreenState createState() => GroceryListScreenState();
}

class GroceryListScreenState extends State<GroceryListScreen> {
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isEditing = false;
  String? _editingListId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newItemController = TextEditingController();
  List<GroceryItem> _items = [];
  List<Recipe> _selectedRecipes = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listArg = ModalRoute.of(context)?.settings.arguments;
      if (listArg == 'new') {
        setState(() {
          _isCreating = true;
        });
      } else if (listArg is String && listArg != 'new') {
        _loadGroceryList(listArg);
      }

      if (listArg == null) {
        _loadGroceryLists();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadGroceryLists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
      await groceryProvider.fetchGroceryLists();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grocery lists: ${e.toString()}')),
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

  Future<void> _loadGroceryList(String listId) async {
    setState(() {
      _isLoading = true;
      _isEditing = true;
      _editingListId = listId;
    });

    try {
      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
      final list = await groceryProvider.getGroceryList(listId);

      _nameController.text = list.name;
      _items = List<GroceryItem>.from(list.items);
      _selectedRecipes = list.recipes;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading grocery list: ${e.toString()}')),
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

  void _addItem() {
    if (_newItemController.text.isEmpty) return;

    setState(() {
      _items.add(GroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _newItemController.text,
        category: 'Other',
        quantity: 1,
        unit: 'pcs',
        purchased: false,
      ));
      _newItemController.clear();
    });
  }

  void _removeItem(String itemId) {
    setState(() {
      _items.removeWhere((item) => item.id == itemId);
    });
  }

  void _toggleItemPurchased(String itemId, bool value) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        _items[index] = _items[index].copyWith(purchased: value);
      }
    });
  }

  Future<void> _saveGroceryList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);

      final groceryList = GroceryList(
        id: _editingListId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        items: _items,
        recipes: _selectedRecipes,
        createdAt: DateTime.now(),
      );

      if (_isEditing) {
        await groceryProvider.updateGroceryList(groceryList);
      } else {
        await groceryProvider.addGroceryList(groceryList);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grocery list ${_isEditing ? 'updated' : 'saved'} successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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

  Future<void> _showRecipeSelectionDialog() async {
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    await recipeProvider.fetchRecipes();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final recipes = recipeProvider.recipes;
            final selectedRecipeIds = {for (var recipe in _selectedRecipes) recipe.id: true};

            return AlertDialog(
              title: const Text('Select Recipes'),
              content: SizedBox(
                width: double.maxFinite,
                child: recipes.isEmpty
                    ? const Center(child: Text('No recipes available'))
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final isSelected = selectedRecipeIds[recipe.id] ?? false;

                    return CheckboxListTile(
                      title: Text(recipe.name ?? 'Unnamed Recipe'),
                      subtitle: Text('${recipe.ingredients.length} ingredients'),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRecipeIds[recipe.id] = true;
                          } else {
                            selectedRecipeIds.remove(recipe.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedRecipes = recipes
                          .where((recipe) => selectedRecipeIds[recipe.id] ?? false)
                          .toList();

                      final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
                      groceryProvider.compileIngredientsFromRecipes(_selectedRecipes);

                      for (final recipe in _selectedRecipes) {
                        for (final ingredient in recipe.ingredients) {
                          final existingIndex = _items.indexWhere(
                                (item) => (item.name ?? '').toLowerCase() == (ingredient.name ?? '').toLowerCase(),
                          );

                          if (existingIndex >= 0) {
                            _items[existingIndex] = _items[existingIndex].copyWith(
                              quantity: (_items[existingIndex].quantity ?? 0) + (ingredient.quantity ?? 0),
                            );
                          } else {
                            _items.add(GroceryItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: ingredient.name ?? 'Unknown Item',
                              category: ingredient.category ?? 'Other',
                              quantity: ingredient.quantity ?? 0.0,
                              unit: ingredient.unit ?? '',
                              purchased: false,
                            ));
                          }
                        }
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add to List'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _shareGroceryList() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to share')),
      );
      return;
    }

    final listName = _nameController.text.isNotEmpty ? _nameController.text : 'Grocery List';

    final itemsByCategory = <String, List<GroceryItem>>{};
    for (final item in _items) {
      itemsByCategory.putIfAbsent(item.category ?? 'Other', () => []).add(item);
    }

    String message = '$listName\n\n';

    itemsByCategory.forEach((category, items) {
      message += '== $category ==\n';
      for (final item in items) {
        final checkmark = item.purchased ? '✓ ' : '[ ] ';
        message += '$checkmark${item.quantity ?? 0} ${item.unit ?? ''} ${item.name ?? 'Unknown Item'}\n';
      }
      message += '\n';
    });

    if (_selectedRecipes.isNotEmpty) {
      message += 'Recipes:\n';
      for (final recipe in _selectedRecipes) {
        message += '- ${recipe.name ?? 'Unnamed Recipe'}\n';
      }
    }

    Share.share(message, subject: listName);
  }

  void _showSendSMSDialog() {
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Grocery List via SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter recipient phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phoneNumber = phoneController.text.trim();
              if (phoneNumber.isNotEmpty) {
                Navigator.pop(context);
                _sendSMS(phoneNumber);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a phone number')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSMS(String phoneNumber) async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to send')),
      );
      return;
    }

    final listName = _nameController.text.isNotEmpty ? _nameController.text : 'Grocery List';

    final itemsByCategory = <String, List<GroceryItem>>{};
    for (final item in _items) {
      itemsByCategory.putIfAbsent(item.category ?? 'Other', () => []).add(item);
    }

    String message = '$listName\n\n';

    itemsByCategory.forEach((category, items) {
      message += '== $category ==\n';
      for (final item in items) {
        final checkmark = item.purchased ? '✓ ' : '[ ] ';
        message += '$checkmark${item.quantity ?? 0} ${item.unit ?? ''} ${item.name ?? 'Unknown Item'}\n';
      }
      message += '\n';
    });

    if (_selectedRecipes.isNotEmpty) {
      message += 'Recipes:\n';
      for (final recipe in _selectedRecipes) {
        message += '- ${recipe.name ?? 'Unnamed Recipe'}\n';
      }
    }

    final encodedMessage = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$phoneNumber?body=$encodedMessage');

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened SMS app for $phoneNumber')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open SMS app')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open SMS app: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating || _isEditing) {
      return _buildEditingScreen();
    } else {
      return _buildListViewScreen();
    }
  }

  Widget _buildListViewScreen() {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final groceryLists = groceryProvider.groceryLists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Lists'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groceryLists.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Grocery Lists',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first grocery list',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isCreating = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Grocery List'),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: groceryLists.length,
        itemBuilder: (context, index) {
          final list = groceryLists[index];
          final completedItems = list.items.where((item) => item.purchased).length;
          final progress = list.items.isEmpty ? 0.0 : completedItems / list.items.length;

          return Dismissible(
            key: Key(list.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Grocery List'),
                  content: Text('Are you sure you want to delete "${list.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              groceryProvider.deleteGroceryList(list.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Grocery list "${list.name}" deleted')),
              );
            },
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(
                  list.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${list.items.length} items'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
                trailing: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                onTap: () {
                  _loadGroceryList(list.id);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isCreating = true;
            _nameController.clear();
            _items = [];
            _selectedRecipes = [];
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEditingScreen() {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final categorizedItems = groceryProvider.categorizedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Grocery List' : 'Create Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGroceryList,
            tooltip: 'Share List',
          ),
          IconButton(
            icon: const Icon(Icons.sms),
            onPressed: _showSendSMSDialog,
            tooltip: 'Send via SMS',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name for your grocery list';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newItemController,
                      decoration: const InputDecoration(
                        labelText: 'Add Item',
                        hintText: 'Enter item name',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addItem(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addItem,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton.icon(
                onPressed: _showRecipeSelectionDialog,
                icon: const Icon(Icons.restaurant_menu),
                label: Text(_selectedRecipes.isEmpty
                    ? 'Add Items from Recipes'
                    : 'Recipe Items (${_selectedRecipes.length})'),
              ),
            ),
            const Divider(),
            Expanded(
              child: _items.isEmpty && categorizedItems.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Items Added',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add items manually or from recipes',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
                  : ListView(
                children: [
                  if (_items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Manually Added Items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ..._items.map((item) {
                    return GroceryItemTile(
                      item: item,
                      onToggle: (value) => _toggleItemPurchased(item.id, value),
                      onDelete: () => _removeItem(item.id),
                    );
                  }),
                  if (categorizedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Items from Recipes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ...categorizedItems.entries.map((entry) {
                    final category = entry.key;
                    final items = entry.value;
                    return ExpansionTile(
                      title: Text(category),
                      children: items.map((item) {
                        return GroceryItemTile(
                          item: item,
                          onToggle: (value) => _toggleItemPurchased(item.id, value),
                          onDelete: () => _removeItem(item.id),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveGroceryList,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(_isEditing ? 'Update Grocery List' : 'Save Grocery List'),
        ),
      ),
    );
  }
}