import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../main.dart' show isEnvLoaded;

class AiService {
  late final String _cohereBaseUrl;
  late final String _cohereApiKey;
  late final bool _isConfigured;
  final http.Client _client = http.Client();
  static final AiService _instance = AiService._internal();

  bool _hasQuotaExceeded = false;
  bool _isRequestCancelled = false;
  bool get isConfigured => _isConfigured && !_hasQuotaExceeded;
  
  factory AiService() {
    return _instance;
  }
  
  AiService._internal() {
    try {
      // Check if environment was loaded properly
      if (isEnvLoaded) {
        _cohereApiKey = dotenv.env['COHERE_API_KEY'] ?? '';
        _cohereBaseUrl = dotenv.env['COHERE_BASE_URL'] ?? 'https://api.cohere.ai';
      } else {
        // Default to empty values if environment isn't loaded
        _cohereApiKey = '';
        _cohereBaseUrl = 'https://api.cohere.ai';
        debugPrint('Using default AI service configuration (no API key)');
      }
          
      _isConfigured = _cohereApiKey.isNotEmpty;
      
      if (!_isConfigured) {
        debugPrint('Warning: Cohere API key not found or empty. AI recommendations will be disabled.');
      }
    } catch (e) {
      debugPrint('Error initializing AI service: $e');
      _cohereApiKey = '';
      _cohereBaseUrl = 'https://api.cohere.ai';
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
    
    // If we've already hit quota limits, return empty list
    if (_hasQuotaExceeded) {
      debugPrint('Using empty recommendations due to previous quota issues');
      return [];
    }
    
    try {
      if (!_isConfigured || _cohereApiKey.isEmpty) {
        throw Exception('Cohere API key not configured');
      }
      
      // Prepare request for Cohere's chat API
      final request = http.Request('POST', Uri.parse('$_cohereBaseUrl/v1/chat'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_cohereApiKey',
        })
        ..body = jsonEncode({
          'message': _createRecommendationPrompt(favoriteGenres, readBooks, count),
          'model': 'command',
          'temperature': 0.7,
          'max_tokens': 800,
          'preamble': 'You are a helpful book recommendation assistant. Return responses in JSON format.',
          'chat_history': []
        });
      
      // Use a stream response to handle timeouts better
      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 15), // Increased timeout slightly
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      // Check if request was cancelled during execution
      if (_isRequestCancelled) {
        return [];
      }

      final response = await http.Response.fromStream(streamedResponse);

      // Check for rate limiting or quota issues
      if (response.statusCode == 429) {
        debugPrint('Cohere API quota exceeded or rate limited');
        // Set the flag so we don't keep trying
        _hasQuotaExceeded = true;
        return [];
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['text'] ?? '';
        
        try {
          // Extract JSON from response
          final jsonPattern = RegExp(r'\{[\s\S]*\}');
          final match = jsonPattern.firstMatch(content);
          
          if (match != null) {
            final jsonContent = match.group(0);
            final recommendationsJson = jsonDecode(jsonContent!);
            
            final recommendations = (recommendationsJson['recommendations'] as List)
                .map((item) => BookRecommendation.fromJson(item))
                .toList();
            
            return recommendations;
          } else {
            debugPrint('Could not find JSON in response');
            return _parseRecommendationsFromText(content);
          }
        } catch (parseError) {
          debugPrint('Error parsing recommendations: $parseError');
          return _parseRecommendationsFromText(content);
        }
      } else {
        debugPrint('Failed to generate recommendations: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate recommendations: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('Request timed out, returning empty recommendations');
      return [];
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      return [];
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