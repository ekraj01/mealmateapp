import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';
import '../widgets/ingredient_input.dart';
import '../widgets/custom_button.dart';

class RecipeEditScreen extends StatefulWidget {
  const RecipeEditScreen({super.key});

  @override
  _RecipeEditScreenState createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _instructionsController = TextEditingController();
  List<Map<String, dynamic>> _ingredients = [];
  bool _isLoading = false;
  String? _editingRecipeId;
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeId = ModalRoute.of(context)!.settings.arguments as String;
      if (recipeId != 'new') {
        _loadRecipe(recipeId);
      } else {
        _ingredients.add({
          'name': '',
          'quantity': 1.0,
          'unit': 'pcs',
          'category': 'Other',
        });
      }
    });
  }

  Future<void> _loadRecipe(String recipeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      final recipe = await recipeProvider.getRecipe(recipeId);
      _editingRecipeId = recipe.id;
      _nameController.text = recipe.name;
      _prepTimeController.text = recipe.prepTime.toString();
      _cookTimeController.text = recipe.cookTime.toString();
      _servingsController.text = recipe.servings.toString();
      _instructionsController.text = recipe.instructions;
      _imageUrl = recipe.imageUrl;
      _ingredients = recipe.ingredients.map((ingredient) {
        return {
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'category': ingredient.category,
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe: $e')),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String recipeId) async {
    if (_imageFile == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('recipe_images')
          .child('$recipeId.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      final recipeId = _editingRecipeId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image if selected
      final uploadedImageUrl = await _uploadImage(recipeId);

      final recipe = Recipe(
        id: recipeId,
        name: _nameController.text,
        prepTime: int.tryParse(_prepTimeController.text) ?? 0,
        cookTime: int.tryParse(_cookTimeController.text) ?? 0,
        servings: int.tryParse(_servingsController.text) ?? 1,
        ingredients: _ingredients.map((ingredient) {
          return Ingredient(
            name: ingredient['name'] as String,
            quantity: ingredient['quantity'] as double,
            unit: ingredient['unit'] as String,
            category: ingredient['category'] as String,
          );
        }).toList(),
        instructions: _instructionsController.text,
        imageUrl: uploadedImageUrl ?? _imageUrl,
      );

      if (_editingRecipeId != null) {
        await recipeProvider.updateRecipe(recipe);
      } else {
        await recipeProvider.addRecipe(recipe);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
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

  @override
  void dispose() {
    _nameController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingRecipeId == null ? 'Create Recipe' : 'Edit Recipe'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipe name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _prepTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Prep Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cookTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Cook Time (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _servingsController,
                decoration: const InputDecoration(
                  labelText: 'Servings',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Text(
                'Image',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _imageUrl != null
                      ? Image.network(_imageUrl!, fit: BoxFit.cover)
                      : const Center(child: Text('Tap to add image')),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._ingredients.asMap().entries.map((entry) {
                final index = entry.key;
                final ingredient = entry.value;
                return IngredientInput(
                  ingredient: ingredient,
                  onUpdate: (updatedIngredient) {
                    setState(() {
                      _ingredients[index] = updatedIngredient;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _ingredients.removeAt(index);
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _ingredients.add({
                      'name': '',
                      'quantity': 1.0,
                      'unit': 'pcs',
                      'category': 'Other',
                    });
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Recipe',
                isLoading: _isLoading,
                onPressed: _saveRecipe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}