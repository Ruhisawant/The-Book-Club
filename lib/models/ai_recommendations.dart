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
    // Don't load recommendations if there are no books
    if (widget.bookData.allBooks.isEmpty) {
      setState(() {
        _recommendations = [];
        _error = 'Add some books to get personalized recommendations';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get favorite genres from user's reading list
      final favoriteGenres = _getFavoriteGenres();
      
      // Get books user has read
      final readBooks = widget.bookData.finishedBooks
          .map((book) => '${book.title} by ${book.author}')
          .toList();
      
      // Check if API key is configured and no quota issues
      if (_aiService.isConfigured) {
        try {
          // Generate recommendations using Cohere
          final recommendations = await _aiService.generateBookRecommendations(
            favoriteGenres: favoriteGenres,
            readBooks: readBooks,
          );
          
          setState(() {
            _recommendations = recommendations;
            _isLoading = false;
            _error = recommendations.isEmpty ? 'No recommendations available' : null;
          });
        } catch (e) {
          debugPrint('Error with Cohere recommendations: $e');
          setState(() {
            _error = 'Could not generate recommendations';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'AI recommendations require an API key';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load recommendations';
        _isLoading = false;
      });
      debugPrint('Error loading recommendations: $e');
    }
  }

  List<String> _getFavoriteGenres() {
    // Extract favorite genres based on user's reading history
    final allBooks = [
      ...widget.bookData.finishedBooks,
      ...widget.bookData.currentlyReadingBooks,
    ];
    
    if (allBooks.isEmpty) {
      return ['fiction', 'non-fiction']; // Default genres
    }
    
    // Using a more sophisticated genre detection approach
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
      'young adult': 0,
      'self-help': 0,
      'business': 0,
      'science': 0,
      'philosophy': 0,
      'poetry': 0,
    };
    
    // Enhanced keyword matching for genre identification
    for (final book in allBooks) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      
      // Mystery/Crime
      if (titleLower.contains('murder') || titleLower.contains('detective') || 
          titleLower.contains('crime') || titleLower.contains('mystery') ||
          authorLower.contains('christie') || authorLower.contains('doyle')) {
        genreCounts['mystery'] = (genreCounts['mystery'] ?? 0) + 1;
      } 
      // Science Fiction
      else if (titleLower.contains('space') || titleLower.contains('planet') ||
               titleLower.contains('robot') || titleLower.contains('alien') ||
               authorLower.contains('asimov') || authorLower.contains('clarke') ||
               authorLower.contains('heinlein')) {
        genreCounts['sci-fi'] = (genreCounts['sci-fi'] ?? 0) + 1;
      } 
      // Fantasy
      else if (titleLower.contains('dragon') || titleLower.contains('magic') ||
               titleLower.contains('sword') || titleLower.contains('wizard') ||
               authorLower.contains('tolkien') || authorLower.contains('rowling') ||
               authorLower.contains('martin')) {
        genreCounts['fantasy'] = (genreCounts['fantasy'] ?? 0) + 1;
      } 
      // Biography/Memoir
      else if (titleLower.contains('life of') || titleLower.contains('memoir') ||
               titleLower.contains('autobiography') || titleLower.contains('biography')) {
        genreCounts['biography'] = (genreCounts['biography'] ?? 0) + 1;
      } 
      // History
      else if (titleLower.contains('history') || titleLower.contains('war') ||
               titleLower.contains('century') || titleLower.contains('revolution')) {
        genreCounts['history'] = (genreCounts['history'] ?? 0) + 1;
      } 
      // Romance
      else if (titleLower.contains('love') || titleLower.contains('romance') ||
               titleLower.contains('heart') || authorLower.contains('sparks')) {
        genreCounts['romance'] = (genreCounts['romance'] ?? 0) + 1;
      }
      // Business
      else if (titleLower.contains('business') || titleLower.contains('entrepreneur') ||
               titleLower.contains('leadership') || titleLower.contains('management')) {
        genreCounts['business'] = (genreCounts['business'] ?? 0) + 1;
      }
      // Self-help
      else if (titleLower.contains('habit') || titleLower.contains('self') ||
               titleLower.contains('improve') || titleLower.contains('happiness')) {
        genreCounts['self-help'] = (genreCounts['self-help'] ?? 0) + 1;
      }
      // Default to fiction as fallback for unidentified genres
      else {
        genreCounts['fiction'] = (genreCounts['fiction'] ?? 0) + 1;
      }
    }
    
    // Sort genres by count and take top 3
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top genres (with at least 1 match)
    return sortedGenres
        .where((e) => e.value > 0)
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
                'AI Book Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_error == null || widget.bookData.allBooks.isNotEmpty)
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
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (widget.bookData.allBooks.isNotEmpty)
                TextButton(
                  onPressed: _loadRecommendations,
                  child: const Text('Try again'),
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

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
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