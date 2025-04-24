import 'package:flutter/material.dart';
import '../models/book_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final BookData _bookData = BookData();
  
  // State management
  String _currentFilter = 'All Books';
  List<Book> _displayedBooks = [];
  List<Book> _recommendedBooks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreBooks = true;
  int _currentPage = 1;
  final int _limit = 20;

  // Category definitions
  final List<String> _categories = [
    'All Books', 'Fiction', 'Non-Fiction', 'Mystery', 'Science Fiction', 
    'Fantasy', 'Biography', 'Self-Help', 'Romance', 'Thriller'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Load both main books and recommendations
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load in parallel for better performance
      await Future.wait([
        _loadBooks(),
        _loadRecommendations(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      _showErrorSnackBar('Failed to load books. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load books based on current filter
  Future<void> _loadBooks() async {
    if (_isLoading && !_isLoadingMore) return;
    
    setState(() {
      if (!_isLoadingMore) {
        _displayedBooks = [];
        _currentPage = 1;
      }
    });

    try {
      final query = _getQueryForFilter(_currentFilter);
      final books = await _bookData.searchBooks(
        query,
        page: _currentPage,
        limit: _limit,
      );
      
      setState(() {
        if (_isLoadingMore) {
          _displayedBooks.addAll(books);
        } else {
          _displayedBooks = books;
        }
        
        // Check if we've reached the end
        _hasMoreBooks = books.length >= _limit;
      });
    } catch (e) {
      debugPrint('Error loading books: $e');
      if (!_isLoadingMore) {
        _showErrorSnackBar('Failed to load books. Please try again.');
      }
    }
  }

  // Load recommended books
  Future<void> _loadRecommendations() async {
    try {
      // Use the getRecommendedBooks method from BookData for better relevance
      // If user has books in their lists, we could use those genres for better recommendations
      final genre = _bookData.allBooks.isNotEmpty ? 'fiction' : 'bestsellers';
      final recommendations = await _bookData.getRecommendedBooks(genre);
      
      setState(() {
        _recommendedBooks = recommendations;
      });
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  // Load more books for infinite scrolling
  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore || !_hasMoreBooks) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final query = _getQueryForFilter(_currentFilter);
      final moreBooks = await _bookData.searchBooks(
        query,
        page: _currentPage,
        limit: _limit,
      );
      
      setState(() {
        _displayedBooks.addAll(moreBooks);
        _hasMoreBooks = moreBooks.length >= _limit;
      });
    } catch (e) {
      debugPrint('Error loading more books: $e');
      // Revert page increment on error
      _currentPage--;
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Helper to get API query based on filter
  String _getQueryForFilter(String filter) {
    if (filter == 'All Books') {
      return 'bestsellers';
    } else {
      // Convert filter to proper query format
      return 'subject:${filter.toLowerCase().replaceAll(' ', '+')}';
    }
  }

  // Change category filter
  void _changeFilter(String newFilter) {
    if (newFilter == _currentFilter) return;
    
    setState(() {
      _currentFilter = newFilter;
      _displayedBooks = [];
      _currentPage = 1;
      _hasMoreBooks = true;
      _isLoading = true;
    });
    
    _loadBooks().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  // Show book details
  void _viewBookDetails(Book book) {
    Navigator.pushNamed(context, '/book_details', arguments: book);
  }

  // Show status change dialog (similar to HomeScreen)
  void _showStatusChangeDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Reading Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Want to Read'),
              leading: Icon(
                Icons.bookmark_border,
                color: _getStatusColor('want_to_read'),
              ),
              selected: book.status == 'want_to_read',
              onTap: () {
                _updateBookStatus(book, 'want_to_read');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Currently Reading'),
              leading: Icon(
                Icons.auto_stories,
                color: _getStatusColor('currently_reading'),
              ),
              selected: book.status == 'currently_reading',
              onTap: () {
                _updateBookStatus(book, 'currently_reading');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Finished'),
              leading: Icon(
                Icons.check_circle_outline,
                color: _getStatusColor('finished'),
              ),
              selected: book.status == 'finished',
              onTap: () {
                _updateBookStatus(book, 'finished');
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

  // Update book status (similar to HomeScreen)
  void _updateBookStatus(Book book, String status) {
    setState(() {
      _bookData.updateBookStatus(book, status);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getSnackbarMessage(status)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Get status color (reused from HomeScreen)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'want_to_read':
        return Colors.blue;
      case 'currently_reading':
        return Colors.orange;
      case 'finished':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get snackbar message (reused from HomeScreen)
  String _getSnackbarMessage(String status) {
    switch (status) {
      case 'want_to_read':
        return 'Book added to Want to Read list';
      case 'currently_reading':
        return 'Book moved to Currently Reading list';
      case 'finished':
        return 'Book marked as Finished';
      default:
        return 'Book status updated';
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Navigate to search screen
  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: _isLoading && _currentPage == 1
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // Category filter
        SliverToBoxAdapter(
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _currentFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _changeFilter(category),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
        ),

        // Recommendations section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended for You',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _loadRecommendations,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),

        // Recommendations carousel
        SliverToBoxAdapter(
          child: SizedBox(
            height: 260,
            child: _recommendedBooks.isEmpty
                ? const Center(
                    child: Text('No recommendations available'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendedBooks.length,
                    itemBuilder: (context, index) {
                      final book = _recommendedBooks[index];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 16),
                        child: BookCard(
                          book: book,
                          onTap: () => _viewBookDetails(book),
                          onStatusTap: () => _showStatusChangeDialog(book),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Main library section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentFilter == 'All Books' ? 'Library' : _currentFilter,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),

        // Main book grid
        _displayedBooks.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No books found in this category',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = _displayedBooks[index];
                      return BookCard(
                        book: book,
                        onTap: () => _viewBookDetails(book),
                        onStatusTap: () => _showStatusChangeDialog(book),
                      );
                    },
                    childCount: _displayedBooks.length,
                  ),
                ),
              ),

        // Loading indicator for infinite scrolling
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),

        // Load more button
        if (_hasMoreBooks && !_isLoadingMore && _displayedBooks.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _loadMoreBooks,
                child: const Text('Load More'),
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }
}