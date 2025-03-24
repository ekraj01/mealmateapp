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

class ItemManagementScreenState extends State<ItemManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (event.x.abs() > 15 || event.y.abs() > 15 || event.z.abs() > 15) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shake detected! List cleared.')),
          );
          final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
          groceryProvider.clearPurchasedAndDeletedItems();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Purchased Items'),
            Tab(text: 'Deleted Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PurchasedItemsTab(),
          DeletedItemsTab(),
        ],
      ),
    );
  }
}

class PurchasedItemsTab extends StatelessWidget {
  const PurchasedItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final purchasedItems = groceryProvider.purchasedItems;

    return purchasedItems.isEmpty
        ? const Center(child: Text('No purchased items'))
        : ListView.builder(
      itemCount: purchasedItems.length,
      itemBuilder: (context, index) {
        final item = purchasedItems[index];
        return ListTile(
          title: Text(item.name ?? 'Unknown Item'),
          subtitle: Text('Purchased on: ${item.purchasedAt ?? 'Unknown'}'),
        );
      },
    );
  }
}

class DeletedItemsTab extends StatelessWidget {
  const DeletedItemsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final groceryProvider = Provider.of<GroceryProvider>(context);
    final deletedItems = groceryProvider.deletedItems;

    return deletedItems.isEmpty
        ? const Center(child: Text('No deleted items'))
        : ListView.builder(
      itemCount: deletedItems.length,
      itemBuilder: (context, index) {
        final item = deletedItems[index];
        return ListTile(
          title: Text(item.name ?? 'Unknown Item'),
          subtitle: Text('Deleted on: ${item.deletedAt ?? 'Unknown'}'),
        );
      },
    );
  }
}