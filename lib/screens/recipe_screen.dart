import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_provider.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  RecipeScreenState createState() => RecipeScreenState();
}

class RecipeScreenState extends State<RecipeScreen> {
  bool _isLoading = false;
  Recipe? _recipe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recipeId = ModalRoute.of(context)?.settings.arguments as String?;
      if (recipeId != null) {
        _loadRecipe(recipeId);
      }
    });
  }

  Future<void> _loadRecipe(String recipeId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
      _recipe = await recipeProvider.getRecipe(recipeId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipe == null
          ? const Center(child: Text('No recipe found'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recipe!.name ?? 'Unnamed Recipe',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Ingredients:'),
            ..._recipe!.ingredients.map((ingredient) => Text(
              '- ${ingredient.quantity ?? 0} ${ingredient.unit ?? ''} ${ingredient.name ?? 'Unknown'}',
            )),
            const SizedBox(height: 16),
            Text('Instructions:'),
            Text(_recipe!.instructions ?? 'No instructions provided'),
          ],
        ),
      ),
    );
  }
}