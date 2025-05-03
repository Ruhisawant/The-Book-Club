import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/book_service.dart';

class BookDetails extends StatefulWidget {
  const BookDetails({super.key});

  @override
  State<BookDetails> createState() => _BookDetailsState();
}

class _BookDetailsState extends State<BookDetails> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _bookDetails;
  bool _isLoading = true;
  bool _hasError = false;
  final List<BookReview> _reviews = [];
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Reviews will be loaded when the book is loaded
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get book data from arguments
    final Book book = ModalRoute.of(context)!.settings.arguments as Book;
    _fetchBookDetails(book.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookDetails(String bookId) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch detailed book info from Google Books API
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/books/v1/volumes/$bookId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _bookDetails = data;
          _isLoading = false;
          
          // Add some mock reviews for demonstration
          if (_reviews.isEmpty) {
            _loadMockReviews();
          }
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      debugPrint('Error fetching book details: $e');
    }
  }

  void _loadMockReviews() {
    // Add some mock reviews for demonstration purposes
    _reviews.add(
      BookReview(
        name: 'Alex Johnson',
        rating: 4.5,
        date: DateTime.now().subtract(const Duration(days: 15)),
        comment: 'This book was a page-turner! I couldn\'t put it down and finished it in one weekend. The characters were well developed and the plot had me guessing until the end.',
      ),
    );
    _reviews.add(
      BookReview(
        name: 'Sarah Miller',
        rating: 5.0,
        date: DateTime.now().subtract(const Duration(days: 30)),
        comment: 'Absolutely brilliant writing. The author has a way with words that transported me into the story. One of my favorites this year!',
      ),
    );
  }

  void _addReview() {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review')),
      );
      return;
    }

    final name = _nameController.text.trim().isNotEmpty 
        ? _nameController.text.trim() 
        : 'Anonymous';

    setState(() {
      _reviews.add(
        BookReview(
          name: name,
          rating: _userRating,
          date: DateTime.now(),
          comment: _reviewController.text.trim(),
        ),
      );
      _reviewController.clear();
      _nameController.clear();
      _userRating = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review added successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Book book = ModalRoute.of(context)!.settings.arguments as Book;

    return Scaffold(
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildBookDetails(book),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load book details',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final Book book = ModalRoute.of(context)!.settings.arguments as Book;
              _fetchBookDetails(book.id);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookDetails(Book book) {
    final volumeInfo = _bookDetails?['volumeInfo'] ?? {};
    
    return CustomScrollView(
      slivers: [
        // App Bar with book cover as background
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildBookCoverHeader(book),
          ),
        ),

        // Book information
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Author
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Book rating
                    Row(
                      children: [
                        _buildRatingStars(book.rating),
                        const SizedBox(width: 8),
                        Text(
                          '${book.rating > 0 ? book.rating.toStringAsFixed(1) : "No rating"} (${volumeInfo['ratingsCount'] ?? 0} ratings)',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Reading status card
              _buildReadingStatusCard(book),

              // Tab bar for navigation between sections
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Add Review'),
                ],
              ),
            ],
          ),
        ),

        // Tab content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(volumeInfo),
              _buildReviewsTab(),
              _buildAddReviewTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookCoverHeader(Book book) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3)],
            ),
          ),
        ),
        // Book cover
        if (book.coverUrl != null)
          Center(
            child: Hero(
              tag: 'book-cover-${book.id}',
              child: Container(
                height: 200,
                width: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.book, size: 60, color: Colors.grey),
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 18);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 18);
        }
      }),
    );
  }

  Widget _buildReadingStatusCard(Book book) {
    final readingStatus = getStatusFromString(book.status);
    final statusColor = readingStatus.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getStatusIcon(book.status), color: statusColor),
              const SizedBox(width: 8),
              Text(
                'Status: ${readingStatus.displayName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Update your reading status',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Reuse the status change dialog from LibraryScreen
                  _showStatusChangeDialog(book);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> volumeInfo) {
    final description = volumeInfo['description'] as String? ?? 'No description available';
    final List<dynamic> categories = volumeInfo['categories'] as List? ?? [];
    final String publisher = volumeInfo['publisher'] as String? ?? 'Unknown';
    final String? publishedDate = volumeInfo['publishedDate'] as String?;
    final int? pageCount = volumeInfo['pageCount'] as int?;
    final String language = volumeInfo['language'] as String? ?? 'Unknown';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 24),

          // Book info table
          Text(
            'Book Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Publisher', publisher),
          if (publishedDate != null) _buildInfoRow('Published Date', publishedDate),
          if (pageCount != null) _buildInfoRow('Pages', pageCount.toString()),
          _buildInfoRow('Language', language),
          
          // Categories
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                return Chip(
                  label: Text(category),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: const Text('Be the first to review'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(BookReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatDate(review.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRatingStars(review.rating),
                const SizedBox(width: 8),
                Text(
                  review.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          
          // Rating selector
          Text(
            'Rating',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _userRating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _userRating = index + 1.0;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Review text field
          TextField(
            controller: _reviewController,
            decoration: const InputDecoration(
              labelText: 'Your Review',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Reading Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(ReadingStatus.wantToRead.displayName),
              leading: Icon(
                Icons.bookmark_border,
                color: ReadingStatus.wantToRead.color,
              ),
              selected: book.status == ReadingStatus.wantToRead.value,
              onTap: () {
                _updateBookStatus(book, ReadingStatus.wantToRead.value);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(ReadingStatus.currentlyReading.displayName),
              leading: Icon(
                Icons.auto_stories,
                color: ReadingStatus.currentlyReading.color,
              ),
              selected: book.status == ReadingStatus.currentlyReading.value,
              onTap: () {
                _updateBookStatus(book, ReadingStatus.currentlyReading.value);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(ReadingStatus.finished.displayName),
              leading: Icon(
                Icons.check_circle_outline,
                color: ReadingStatus.finished.color,
              ),
              selected: book.status == ReadingStatus.finished.value,
              onTap: () {
                _updateBookStatus(book, ReadingStatus.finished.value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _updateBookStatus(Book book, String status) {
    final bookData = BookData();
    setState(() {
      bookData.updateBookStatus(book, status);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getSnackbarMessage(status)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getSnackbarMessage(String status) {
    final readingStatus = getStatusFromString(status);
    switch (readingStatus) {
      case ReadingStatus.wantToRead:
        return 'Book added to Want to Read list';
      case ReadingStatus.currentlyReading:
        return 'Book moved to Currently Reading list';
      case ReadingStatus.finished:
        return 'Book marked as Finished';
    }
  }

  IconData _getStatusIcon(String status) {
    final readingStatus = getStatusFromString(status);
    switch (readingStatus) {
      case ReadingStatus.wantToRead:
        return Icons.bookmark_border;
      case ReadingStatus.currentlyReading:
        return Icons.auto_stories;
      case ReadingStatus.finished:
        return Icons.check_circle_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Book Review Model
class BookReview {
  final String name;
  final double rating;
  final DateTime date;
  final String comment;

  BookReview({
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
  });
}