import 'package:flutter/material.dart';
import '../models/book_service.dart';
import '../models/ai_service.dart';

class RecommendationsSection extends StatefulWidget {
  final BookData bookData;
  
  const RecommendationsSection({
    super.key,
    required this.bookData,
  });
  
  @override
  State<RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<RecommendationsSection> {
  late final AiService _aiService;
  bool _isLoading = false;
  List<BookRecommendation> _recommendations = [];
  String? _error;
  bool _usingLocalRecommendations = false;

  @override
  void initState() {
    super.initState();
    _initializeAiService();
  }
  
  void _initializeAiService() {
    try {
      _aiService = AiService();
      _loadRecommendations();
    } catch (e) {
      setState(() {
        _error = 'Could not initialize AI service';
      });
      debugPrint('Error initializing AI service: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get favorite genres from user's reading list
      final favoriteGenres = _getFavoriteGenres();
      
      List<BookRecommendation> recommendations;
      
      // Check if API key is configured and no quota issues
      if (_aiService.isConfigured) {
        // Get books user has read
        final readBooks = widget.bookData.finishedBooks
            .map((book) => '${book.title} by ${book.author}')
            .toList();

        try {
          // Generate recommendations using OpenAI
          recommendations = await _aiService.generateBookRecommendations(
            favoriteGenres: favoriteGenres,
            readBooks: readBooks,
          );
          
          // Check if we got local recommendations instead
          _usingLocalRecommendations = !_aiService.isConfigured;
        } catch (e) {
          debugPrint('Error with OpenAI recommendations: $e');
          // If API call fails, use local recommendations
          recommendations = await _aiService.getLocalRecommendations(
            favoriteGenres: favoriteGenres,
          );
          _usingLocalRecommendations = true;
        }
      } else {
        // Use local fallback if API key is not available or quota exceeded
        recommendations = await _aiService.getLocalRecommendations(
          favoriteGenres: favoriteGenres,
        );
        _usingLocalRecommendations = true;
      }

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
        _error = null; // Clear any previous errors
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load recommendations';
        _isLoading = false;
      });
      debugPrint('Error loading recommendations: $e');
      
      // Try local recommendations as fallback even if other approaches fail
      _loadLocalRecommendationsFallback();
    }
  }
  
  // Fallback to load local recommendations if everything else fails
  Future<void> _loadLocalRecommendationsFallback() async {
    try {
      final favoriteGenres = _getFavoriteGenres();
      final recommendations = await _aiService.getLocalRecommendations(
        favoriteGenres: favoriteGenres,
      );
      
      setState(() {
        _recommendations = recommendations;
        _usingLocalRecommendations = true;
        _error = null; // Clear any previous errors
      });
    } catch (e) {
      debugPrint('Error loading local recommendations fallback: $e');
      // Keep the existing error state
    }
  }

  List<String> _getFavoriteGenres() {
    // Simple logic to extract favorite genres
    final allBooks = [
      ...widget.bookData.finishedBooks,
      ...widget.bookData.currentlyReadingBooks,
    ];
    
    if (allBooks.isEmpty) {
      return ['fiction', 'non-fiction']; // Default genres
    }
    
    // Since there's no direct genre information, use a simple keyword matching approach
    final Map<String, int> genreCounts = {
      'fiction': 0,
      'non-fiction': 0,
      'mystery': 0,
      'sci-fi': 0,
      'fantasy': 0,
      'biography': 0,
      'history': 0,
      'romance': 0,
      'thriller': 0,
    };
    
    // Simple keyword matching for genre identification
    for (final book in allBooks) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      
      // This is a simple heuristic approach - not perfect but gives some variety
      if (titleLower.contains('murder') || titleLower.contains('detective') || 
          titleLower.contains('crime')) {
        genreCounts['mystery'] = (genreCounts['mystery'] ?? 0) + 1;
      } else if (titleLower.contains('space') || titleLower.contains('planet') ||
                 authorLower.contains('asimov') || authorLower.contains('clarke')) {
        genreCounts['sci-fi'] = (genreCounts['sci-fi'] ?? 0) + 1;
      } else if (titleLower.contains('dragon') || titleLower.contains('magic') ||
                 authorLower.contains('tolkien') || authorLower.contains('rowling')) {
        genreCounts['fantasy'] = (genreCounts['fantasy'] ?? 0) + 1;
      } else if (titleLower.contains('life of') || titleLower.contains('memoir')) {
        genreCounts['biography'] = (genreCounts['biography'] ?? 0) + 1;
      } else if (titleLower.contains('history') || titleLower.contains('war')) {
        genreCounts['history'] = (genreCounts['history'] ?? 0) + 1;
      } else if (titleLower.contains('love') || titleLower.contains('romance')) {
        genreCounts['romance'] = (genreCounts['romance'] ?? 0) + 1;
      } else {
        // Default to fiction as fallback
        genreCounts['fiction'] = (genreCounts['fiction'] ?? 0) + 1;
      }
    }
    
    // Sort genres by count and take top 3
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedGenres
        .take(3)
        .map((e) => e.key)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended for you',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_error == null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadRecommendations,
                  tooltip: 'Refresh recommendations',
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRecommendationsContent(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline, size: 40, color: Colors.amber[700]),
              const SizedBox(height: 8),
              Text(
                _aiService.isConfigured
                    ? 'Could not load recommendations'
                    : 'AI recommendations require an API key',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              TextButton(
                onPressed: _loadLocalRecommendationsFallback,
                child: const Text('Show default recommendations'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No recommendations available yet',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_usingLocalRecommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Using default recommendations',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = _recommendations[index];
              return _buildRecommendationCard(recommendation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(BookRecommendation recommendation) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'by ${recommendation.author}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                recommendation.genre,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                recommendation.why,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}