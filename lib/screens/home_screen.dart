import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../providers/grocery_provider.dart';
import '../widgets/grocery_summary.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data only if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isLoggedIn) {
        Provider.of<GroceryProvider>(context, listen: false).fetchGroceryLists();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final groceryProvider = Provider.of<GroceryProvider>(context);

    // Navigate to login if user is not logged in
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner & Grocery App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(authProvider.currentUser?.displayName ?? 'User'),
              accountEmail: Text(authProvider.currentUser?.email ?? 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: authProvider.currentUser?.photoURL != null
                    ? NetworkImage(authProvider.currentUser!.photoURL!)
                    : null,
                child: authProvider.currentUser?.photoURL == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
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
                Navigator.pushNamed(context, '/recipe');
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
              leading: const Icon(Icons.list),
              title: const Text('Item Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/item_management');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                authProvider.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.isLoggedIn) {
            await groceryProvider.fetchGroceryLists();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${authProvider.currentUser?.displayName ?? 'there'}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'What are you cooking today?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Current Grocery Lists', () {
                Navigator.pushNamed(context, '/grocery');
              }),
              const SizedBox(height: 12),
              groceryProvider.groceryLists.isEmpty
                  ? _buildEmptyState(
                'No grocery lists',
                'Create a grocery list for your next shopping trip',
                Icons.shopping_cart,
                    () {
                  Navigator.pushNamed(context, '/grocery');
                },
              )
                  : Column(
                children: groceryProvider.groceryLists
                    .take(2)
                    .map((list) => GrocerySummary(groceryList: list))
                    .toList(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Quick Actions', null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Add Recipe',
                      Icons.add_circle,
                      Colors.orange,
                          () {
                        Navigator.pushNamed(context, '/recipe');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'Create Grocery List',
                      Icons.add_shopping_cart,
                      Colors.purple,
                          () {
                        Navigator.pushNamed(context, '/grocery');
                      },
                    ),
                  ),
                ],
              ),
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
                      Navigator.pushNamed(context, '/recipe', arguments: 'new');
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

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
      String title,
      String message,
      IconData icon,
      VoidCallback onAction,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            child: const Text('Add Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}