import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'models/book_details.dart';
import 'navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Error loading environment variables: $e');
  }
  
  await Firebase.initializeApp();
  runApp(const BookClubApp());
}

class BookClubApp extends StatelessWidget {
  const BookClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const Navigation(currentIndex: 0),
        '/library': (context) => const Navigation(currentIndex: 1),
        '/discussion': (context) => const Navigation(currentIndex: 2),
        '/profile': (context) => const Navigation(currentIndex: 3),
        '/book_details': (context) => const BookDetails(),
      },
    );
  }
}