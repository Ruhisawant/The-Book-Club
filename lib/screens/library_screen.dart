import 'package:flutter/material.dart';
import '../models/book_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final BookData _bookData = BookData();
  
  String _currentFilter = 'All Books';
  List<Book> _displayedBooks = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'All Books', 'Fiction', 'Non-Fiction', 'Mystery', 'Science Fiction', 
    'Fantasy', 'Biography', 'Self-Help', 'Romance', 'Thriller'
  ];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _displayedBooks = [];
    });

    try {
      List<Book> booksToDisplay = [];
      final int booksPerGenre = 2;

      if (_currentFilter == 'All Books') {
        final genres = [
          'fiction', 'mystery', 'science-fiction', 'fantasy', 
          'biography', 'romance', 'thriller', 'horror', 
          'history', 'poetry', 'young-adult', 'classics'
        ];

        final futures = genres.map((genre) async {
          try {
            final books = await _bookData.getBooksByGenre(genre);
            return books.take(booksPerGenre).toList();
          } catch (e) {
            debugPrint('Error loading $genre books: $e');
            return <Book>[];
          }
        }).toList();

        final results = await Future.wait(futures);

        for (var bookList in results) {
          booksToDisplay.addAll(bookList);
        }

        if (booksToDisplay.length > 20) {
          booksToDisplay = booksToDisplay.sublist(0, 20);
        }

      } else {
        final genre = _getGenreFromFilter(_currentFilter);
        booksToDisplay = await _bookData.getBooksByGenre(genre);
      }

      setState(() {
        _displayedBooks = booksToDisplay;
      });

    } catch (e) {
      _getSnackbarMessage('Failed to load books. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to get genre format based on filter
  String _getGenreFromFilter(String filter) {
    if (filter == 'All Books') {
      return 'bestsellers';
    } else {
      return filter.toLowerCase().replaceAll(' ', '-');
    }
  }

  // Change category filter
  void _changeFilter(String newFilter) {
    if (newFilter == _currentFilter) return;
    
    setState(() {
      _currentFilter = newFilter;
    });
    
    _fetchBooks();
  }

  // Show book details
  void _viewBookDetails(Book book) {
    Navigator.pushNamed(context, '/book_details', arguments: book);
  }

  // Show status change dialog using the enum-based approach
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

  // Update book status using the BookData method
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

  // Get snackbar message based on status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Book Library'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBooks,
        child: _isLoading
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

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _currentFilter == 'All Books' 
                  ? 'All Books' 
                  : '$_currentFilter Books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),

        // Books grid
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
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = _displayedBooks[index];
                      
                      return LibraryBookCard(
                        book: book,
                        onTap: () => _viewBookDetails(book),
                        onStatusTap: () => _showStatusChangeDialog(book),
                        showGenreLabel: _currentFilter == 'All Books',
                      );
                    },
                    childCount: _displayedBooks.length,
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
