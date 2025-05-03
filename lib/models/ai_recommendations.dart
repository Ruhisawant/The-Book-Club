import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../services/ai_service.dart';

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
      // Instead of determining genres, use genres directly from Google Books API
      final readBooks = widget.bookData.finishedBooks
          .map((book) => '${book.title} by ${book.author}')
          .toList();
      
      // Extract genres directly from books (assuming BookData has this info)
      final genres = _getGenresFromBooks();
      
      if (_aiService.isConfigured) {
        try {
          final recommendations = await _aiService.generateBookRecommendations(
            favoriteGenres: genres,
            readBooks: readBooks,
          );
          
          setState(() {
            _recommendations = recommendations;
            _isLoading = false;
            _error = recommendations.isEmpty ? 'No recommendations available' : null;
          });
        } catch (e) {
          debugPrint('Error with recommendations: $e');
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

  List<String> _getGenresFromBooks() {
    final Set<String> uniqueGenres = {};
    
    final allBooks = [
      ...widget.bookData.finishedBooks,
      ...widget.bookData.currentlyReadingBooks,
    ];
    
    for (final book in allBooks) {
      // Check for fiction/non-fiction keywords in titles
      final lowerTitle = book.title.toLowerCase();
      
      // Try to infer genres from book titles and authors
      if (lowerTitle.contains('novel') || 
          lowerTitle.contains('fiction') || 
          lowerTitle.contains('story')) {
        uniqueGenres.add('fiction');
      }
      
      if (lowerTitle.contains('history') || 
          lowerTitle.contains('biography') || 
          lowerTitle.contains('memoir') ||
          lowerTitle.contains('guide')) {
        uniqueGenres.add('non-fiction');
      }
      
      // Add more specific genres based on keywords
      if (lowerTitle.contains('science') || lowerTitle.contains('physics') || 
          lowerTitle.contains('chemistry') || lowerTitle.contains('biology')) {
        uniqueGenres.add('science');
      }
      
      if (lowerTitle.contains('mystery') || lowerTitle.contains('thriller') || 
          lowerTitle.contains('detective')) {
        uniqueGenres.add('mystery');
      }
      
      if (lowerTitle.contains('fantasy') || lowerTitle.contains('magic') || 
          lowerTitle.contains('dragon')) {
        uniqueGenres.add('fantasy');
      }
    }
    
    // If no genres found, provide some basic ones
    if (uniqueGenres.isEmpty) {
      return ['fiction', 'non-fiction'];
    }
    
    // Return only up to 3 genres to keep the API request small
    return uniqueGenres.take(3).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small handle indicator at top for visual cue
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Book Recommendations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (_error == null || widget.bookData.allBooks.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _isLoading ? null : _loadRecommendations,
                  tooltip: 'Refresh recommendations',
                  style: IconButton.styleFrom(
                    backgroundColor: _isLoading 
                        ? Colors.grey[200] 
                        : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationsContent(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Generating personalized recommendations...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.lightbulb_outline, 
                size: 40, 
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              if (widget.bookData.allBooks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton.icon(
                    onPressed: _loadRecommendations,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try again'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendations.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final recommendation = _recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(BookRecommendation recommendation) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(right: 16),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.book,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'by ${recommendation.author}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recommendation.genre,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}