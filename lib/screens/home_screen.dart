import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mealmateapp/models/grocery_list_model.dart';
import 'package:mealmateapp/models/recipe_model.dart';
import 'package:mealmateapp/providers/grocery_provider.dart';
import 'package:mealmateapp/providers/recipe_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroceryProvider>(context, listen: false).fetchGroceryLists();
      Provider.of<RecipeProvider>(context, listen: false).fetchRecipes();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final groceryLists = groceryProvider.groceryLists;
    final recipes = recipeProvider.recipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MealMate'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.teal.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'MealMate',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Recipes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/recipe_list');
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Grocery Lists'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/grocery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Item Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/item_management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Welcome to MealMate',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        'Add Recipe',
                        Icons.add_circle,
                        Colors.orangeAccent,
                            () {
                          Navigator.pushNamed(context, '/recipe_list');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        'New Grocery List',
                        Icons.add_shopping_cart,
                        Colors.teal,
                            () {
                          Navigator.pushNamed(context, '/grocery', arguments: 'new');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Grocery Lists',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              groceryLists.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No grocery lists yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groceryLists.length > 3 ? 3 : groceryLists.length,
                itemBuilder: (context, index) {
                  final list = groceryLists[index];
                  return AnimatedGroceryListTile(
                    list: list,
                    onTap: () {
                      Navigator.pushNamed(context, '/grocery', arguments: list.id);
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Recipes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              recipes.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No recipes yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipes.length > 3 ? 3 : recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return AnimatedRecipeTile(
                    recipe: recipe,
                    onTap: () {
                      Navigator.pushNamed(context, '/recipe', arguments: recipe.id);
                    },
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: const Text('Add New Recipe'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/recipe_edit', arguments: 'new');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart),
                    title: const Text('Create Grocery List'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/grocery', arguments: 'new');
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AnimatedGroceryListTile extends StatefulWidget {
  final GroceryList list;
  final VoidCallback onTap;

  const AnimatedGroceryListTile({
    super.key,
    required this.list,
    required this.onTap,
  });

  @override
  _AnimatedGroceryListTileState createState() => _AnimatedGroceryListTileState();
}

class _AnimatedGroceryListTileState extends State<AnimatedGroceryListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedItems = widget.list.items.where((item) => item.purchased).length;
    final progress = widget.list.items.isEmpty ? 0.0 : completedItems / widget.list.items.length;

    return SlideTransition(
      position: _animation,
      child: Card(
        child: ListTile(
          title: Text(
            widget.list.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.list.items.length} items',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ],
          ),
          trailing: Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class AnimatedRecipeTile extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const AnimatedRecipeTile({
    super.key,
    required this.recipe,
    required this.onTap,
  });

  @override
  _AnimatedRecipeTileState createState() => _AnimatedRecipeTileState();
}

class _AnimatedRecipeTileState extends State<AnimatedRecipeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: Card(
        child: ListTile(
          title: Text(
            widget.recipe.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            '${widget.recipe.ingredients.length} ingredients',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}