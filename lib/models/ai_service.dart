import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  late final String _openAIBaseUrl;
  late final String _openAIApiKey;
  late final bool _isConfigured;
  
  // Getter for configuration status
  bool get isConfigured => _isConfigured;
  
  // Singleton pattern
  static final AiService _instance = AiService._internal();
  
  factory AiService() {
    return _instance;
  }
  
  AiService._internal() {
    try {
      _openAIApiKey = (dotenv.env['OPENAI_API_KEY'] ?? '').replaceAll("'", "").trim();
      _openAIBaseUrl = (dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1').replaceAll("'", "").trim();
          
      _isConfigured = _openAIApiKey.isNotEmpty;
      
      if (!_isConfigured) {
        debugPrint('Warning: OpenAI API key not found in environment variables');
      }
    } catch (e) {
      debugPrint('Error initializing AI service: $e');
      _openAIApiKey = '';
      _openAIBaseUrl = 'https://api.openai.com/v1';
      _isConfigured = false;
    }
  }

  // Generate personalized book recommendations based on user's reading habits
  Future<List<BookRecommendation>> generateBookRecommendations({
    required List<String> favoriteGenres,
    required List<String> readBooks,
    int count = 5,
  }) async {
    try {
      if (!_isConfigured || _openAIApiKey.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }
      
      final response = await http.post(
        Uri.parse('$_openAIBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a helpful book recommendation assistant. Return responses in JSON format.'
            },
            {
              'role': 'user',
              'content': _createRecommendationPrompt(favoriteGenres, readBooks, count),
            }
          ],
          'temperature': 0.7,
          'max_tokens': 800,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        try {
          final recommendationsJson = jsonDecode(content);
          final recommendations = (recommendationsJson['recommendations'] as List)
              .map((item) => BookRecommendation.fromJson(item))
              .toList();
          
          return recommendations;
        } catch (parseError) {
          debugPrint('Error parsing recommendations: $parseError');
          // Fallback parsing for non-JSON responses
          return _parseRecommendationsFromText(content);
        }
      } else {
        debugPrint('Failed to generate recommendations: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate recommendations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      throw Exception('Error generating recommendations: $e');
    }
  }

  // Helper method to create the prompt for recommendation generation
  String _createRecommendationPrompt(List<String> genres, List<String> readBooks, int count) {
    final genresText = genres.isEmpty ? 'general fiction' : genres.join(', ');
    final booksText = readBooks.isEmpty 
        ? 'None yet' 
        : readBooks.take(5).join(', ') + (readBooks.length > 5 ? ', and others' : '');
    
    return '''
    I need book recommendations based on my reading preferences.
    
    My favorite genres: $genresText
    Books I've already read: $booksText
    
    Please suggest $count books I might enjoy based on these preferences.
    
    Return your response as a JSON object with this structure:
    {
      "recommendations": [
        {
          "title": "Book Title",
          "author": "Author Name",
          "genre": "Primary Genre",
          "why": "Brief reason for recommendation"
        }
      ]
    }
    ''';
  }
  
  // Fallback method to parse recommendations from text format
  List<BookRecommendation> _parseRecommendationsFromText(String text) {
    final recommendations = <BookRecommendation>[];
    
    // Try to extract book recommendations from free text
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Look for patterns like "- Title by Author" or "1. Title by Author"
      final match = RegExp(r'(?:[-•*]|\d+\.)\s*([^"]+)\s+by\s+([^,\.]+)').firstMatch(line);
      if (match != null && match.groupCount >= 2) {
        recommendations.add(BookRecommendation(
          title: match.group(1)?.trim() ?? 'Unknown Title',
          author: match.group(2)?.trim() ?? 'Unknown Author',
          genre: '',
          why: '',
        ));
      }
    }
    
    return recommendations;
  }

  // Method to cancel ongoing requests if needed
  void dispose() {
    // Add cleanup code if needed
  }
}

// Model class for book recommendations
class BookRecommendation {
  final String title;
  final String author;
  final String genre;
  final String why;
  
  BookRecommendation({
    required this.title,
    required this.author,
    required this.genre,
    required this.why,
  });
  
  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      title: json['title'] ?? 'Unknown Title',
      author: json['author'] ?? 'Unknown Author',
      genre: json['genre'] ?? '',
      why: json['why'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'genre': genre,
      'why': why,
    };
  }
  
  @override
  String toString() {
    return '$title by $author';
  }
}