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
    // Skip if not configured
    if (!_aiService.isConfigured) {
      setState(() {
        _error = 'API key not configured';
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

      // Generate recommendations
      final recommendations = await _aiService.generateBookRecommendations(
        favoriteGenres: favoriteGenres,
        readBooks: readBooks,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load recommendations';
        _isLoading = false;
      });
      debugPrint('Error loading recommendations: $e');
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
    
    final Map<String, int> genreCounts = {};
    
    // for (final book in allBooks) {
    //   final genres = book.genres;
    //   for (final genre in genres) {
    //     genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    //   }
    // }
    
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