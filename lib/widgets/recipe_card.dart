import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String? name;
  final String? imageUrl;

  const RecipeCard({
    super.key,
    this.name,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (imageUrl != null)
            Image.network(imageUrl!, height: 100, fit: BoxFit.cover),
          Text(name ?? 'Unnamed Recipe'),
        ],
      ),
    );
  }
}