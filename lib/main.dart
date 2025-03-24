import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mealmateapp/firebase_options.dart';
import 'package:mealmateapp/screens/home_screen.dart';
import 'package:mealmateapp/screens/login_screen.dart';
import 'package:mealmateapp/screens/signup_screen.dart'; // Add this import
import 'package:mealmateapp/screens/recipe_screen.dart';
import 'package:mealmateapp/screens/grocery_list_screen.dart';
import 'package:mealmateapp/screens/item_management_screen.dart';
import 'package:mealmateapp/screens/settings_screen.dart';
import 'package:mealmateapp/services/auth_provider.dart';
import 'package:mealmateapp/providers/grocery_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GroceryProvider()),
      ],
      child: MaterialApp(
        title: 'MealMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(), // Add this route
          '/recipe': (context) => const RecipeScreen(),
          '/grocery': (context) => const GroceryListScreen(),
          '/item_management': (context) => const ItemManagementScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}