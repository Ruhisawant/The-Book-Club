import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../main.dart' show isEnvLoaded;

class AiService {
  late final String _cohereBaseUrl;
  late final String _cohereApiKey;
  late final bool _isConfigured;
  
  // Track API quota/rate limit issues
  bool _hasQuotaExceeded = false;
  
  // Add a client with proper timeout
  final http.Client _client = http.Client();
  
  // Add request cancellation support
  bool _isRequestCancelled = false;
  
  // Getter for configuration status
  bool get isConfigured => _isConfigured && !_hasQuotaExceeded;
  
  // Singleton pattern
  static final AiService _instance = AiService._internal();
  
  factory AiService() {
    return _instance;
  }
  
  AiService._internal() {
    try {
      // Check if environment was loaded properly
      if (isEnvLoaded) {
        _cohereApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
        _cohereBaseUrl = dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';
      } else {
        // Default to empty values if environment isn't loaded
        _cohereApiKey = '';
        _cohereBaseUrl = 'https://api.openai.com/v1';
        debugPrint('Using default AI service configuration (no API key)');
      }
          
      _isConfigured = _cohereApiKey.isNotEmpty;
      
      if (!_isConfigured) {
        debugPrint('Warning: OpenAI API key not found or empty. AI recommendations will be disabled.');
      }
    } catch (e) {
      debugPrint('Error initializing AI service: $e');
      _cohereApiKey = '';
      _cohereBaseUrl = 'https://api.openai.com/v1';
      _isConfigured = false;
    }
  }

  // Generate personalized book recommendations based on user's reading habits
  Future<List<BookRecommendation>> generateBookRecommendations({
    required List<String> favoriteGenres,
    required List<String> readBooks,
    int count = 5,
  }) async {
    // Reset cancellation flag
    _isRequestCancelled = false;
    
    // If we've already hit quota limits, go straight to fallback
    if (_hasQuotaExceeded) {
      debugPrint('Using local recommendations due to previous quota issues');
      return getLocalRecommendations(favoriteGenres: favoriteGenres);
    }
    
    try {
      if (!_isConfigured || _cohereApiKey.isEmpty) {
        throw Exception('OpenAI API key not configured');
      }
      
      // Move this to a separate method to improve readability
      final request = http.Request('POST', Uri.parse('$_cohereBaseUrl/chat/completions'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_cohereApiKey',
        })
        ..body = jsonEncode({
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
        });
      
      // Use a stream response to handle timeouts better
      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 15), // Increased timeout slightly
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      // Check if request was cancelled during execution
      if (_isRequestCancelled) {
        return getLocalRecommendations(favoriteGenres: favoriteGenres);
      }

      final response = await http.Response.fromStream(streamedResponse);

      // Check for rate limiting or quota issues
      if (response.statusCode == 429) {
        debugPrint('OpenAI API quota exceeded or rate limited');
        // Set the flag so we don't keep trying
        _hasQuotaExceeded = true;
        // Use local recommendations instead
        return getLocalRecommendations(favoriteGenres: favoriteGenres);
      }

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
          return _parseRecommendationsFromText(content);
        }
      } else {
        debugPrint('Failed to generate recommendations: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate recommendations: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('Request timed out, using local recommendations');
      return getLocalRecommendations(favoriteGenres: favoriteGenres);
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      // If we hit any error, fall back to local recommendations
      return getLocalRecommendations(favoriteGenres: favoriteGenres);
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

  // Generate fallback recommendations when API is not available
  Future<List<BookRecommendation>> getLocalRecommendations({
    required List<String> favoriteGenres,
  }) async {
    // Create some static recommendations based on popular books
    final allRecommendations = [
      BookRecommendation(
        title: "Project Hail Mary",
        author: "Andy Weir",
        genre: "Science Fiction",
        why: "A thrilling science fiction adventure with problem-solving and humor",
      ),
      BookRecommendation(
        title: "Atomic Habits",
        author: "James Clear",
        genre: "Self-Help",
        why: "Practical strategies for building good habits and breaking bad ones",
      ),
      BookRecommendation(
        title: "The Midnight Library",
        author: "Matt Haig",
        genre: "Fiction",
        why: "A thought-provoking story about the choices that shape our lives",
      ),
      BookRecommendation(
        title: "The Thursday Murder Club",
        author: "Richard Osman",
        genre: "Mystery",
        why: "A charming murder mystery with witty characters and clever plot twists",
      ),
      BookRecommendation(
        title: "Educated",
        author: "Tara Westover",
        genre: "Memoir",
        why: "A powerful memoir about the struggle for self-invention",
      ),
      BookRecommendation(
        title: "Dune",
        author: "Frank Herbert",
        genre: "Science Fiction",
        why: "A classic of science fiction with complex world-building",
      ),
      BookRecommendation(
        title: "The Silent Patient",
        author: "Alex Michaelides",
        genre: "Thriller",
        why: "A psychological thriller with a shocking twist",
      ),
      BookRecommendation(
        title: "A Gentleman in Moscow",
        author: "Amor Towles",
        genre: "Historical Fiction",
        why: "A beautifully written story of a man confined to a luxury hotel",
      ),
      BookRecommendation(
        title: "The Vanishing Half",
        author: "Brit Bennett",
        genre: "Literary Fiction",
        why: "A thought-provoking exploration of race, identity, and sisterhood",
      ),
      BookRecommendation(
        title: "Where the Crawdads Sing",
        author: "Delia Owens",
        genre: "Mystery",
        why: "A beautiful story combining nature, mystery, and coming-of-age",
      ),
    ];
    
    // Filter and sort recommendations based on user's favorite genres
    final filteredBooks = allRecommendations.where((book) {
      final genreLower = book.genre.toLowerCase();
      return favoriteGenres.isEmpty || 
             favoriteGenres.any((genre) => 
                genreLower.contains(genre.toLowerCase()));
    }).toList();
    
    // If we have matching recommendations, return those first
    final result = [...filteredBooks];
    
    // Add remaining books if we don't have enough recommendations
    if (result.length < 5) {
      final remainingBooks = allRecommendations
          .where((book) => !result.contains(book))
          .take(5 - result.length)
          .toList();
      result.addAll(remainingBooks);
    }
    
    // Take only the top 5
    return result.take(5).toList();
  }
  
  // Reset quota exceeded flag for testing
  void resetQuotaFlag() {
    _hasQuotaExceeded = false;
  }
  
  // Cancel ongoing requests
  void cancelRequest() {
    _isRequestCancelled = true;
  }
  
  // Method to cancel ongoing requests and clean up resources
  void dispose() {
    cancelRequest();
    _client.close();
  }
}

// Custom Exception
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
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