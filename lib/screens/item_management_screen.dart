import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import '../providers/grocery_provider.dart';

class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  ItemManagementScreenState createState() => ItemManagementScreenState();
}

class ItemManagementScreenState extends State<ItemManagementScreen> {
  bool _isShakeDetected = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _listenToShake();
  }

  /// Listens to accelerometer events to detect a shake gesture.
  void _listenToShake() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      const double threshold = 20.0;
      if (event.x.abs() > threshold || event.y.abs() > threshold || event.z.abs() > threshold) {
        if (!_isShakeDetected) {
          setState(() {
            _isShakeDetected = true;
          });
          _clearItems();
        }
      }
    });
  }

  /// Clears purchased and deleted items when a shake is detected.
  void _clearItems() {
    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    groceryProvider.clearPurchasedAndDeletedItems();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Purchased and deleted items cleared')),
    );
    setState(() {
      _isShakeDetected = false;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final purchasedItems = groceryProvider.purchasedItems;
    final deletedItems = groceryProvider.deletedItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchased Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            purchasedItems.isEmpty
                ? const Center(child: Text('No purchased items'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: purchasedItems.length,
              itemBuilder: (context, index) {
                final item = purchasedItems[index];
                return Dismissible(
                  key: Key(item.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    groceryProvider.clearPurchasedAndDeletedItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} removed from purchased')),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Purchased on: ${item.purchasedAt?.toString() ?? 'Unknown'}',
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Deleted Items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            deletedItems.isEmpty
                ? const Center(child: Text('No deleted items'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: deletedItems.length,
              itemBuilder: (context, index) {
                final item = deletedItems[index];
                return Dismissible(
                  key: Key(item.id),
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.restore, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.green,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.restore, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    groceryProvider.clearPurchasedAndDeletedItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} restored')),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Deleted on: ${item.deletedAt?.toString() ?? 'Unknown'}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}