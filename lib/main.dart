import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'models/book_details.dart';
import 'navigation.dart';

bool isEnvLoaded = false;

void testEnvVariables() {
  final googleApiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'];
  final cohereApiKey = dotenv.env['COHERE_API_KEY'];
  
  debugPrint('Google Books API Key available: ${googleApiKey != null && googleApiKey.isNotEmpty}');
  debugPrint('Cohere API Key available: ${cohereApiKey != null && cohereApiKey.isNotEmpty}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('Environment variables loaded successfully');
    isEnvLoaded = true;
  } catch (e) {
    debugPrint('Error loading environment variables: $e');
    dotenv.testLoad(fileInput: '''
      COHERE_API_KEY=
      COHERE_BASE_URL=https://api.cohere.ai
    ''');
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