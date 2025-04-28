import 'package:flutter/material.dart';
import '../models/book_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookData _bookData = BookData();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Empty when first loaded
    } catch (e) {
      debugPrint('Error loading books: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Reading Lists'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Want to Read'),
              Tab(text: 'Reading'),
              Tab(text: 'Finished'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildBookList(_bookData.wantToReadBooks, 'want_to_read'),
                  _buildBookList(_bookData.currentlyReadingBooks, 'currently_reading'),
                  _buildBookList(_bookData.finishedBooks, 'finished'),
                ],
              ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books, String listType) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No books in this list yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _homeBookCard(book);
      },
    );
  }

  Widget _homeBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      height: 120,
                      width: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, _) => Container(
                        height: 120,
                        width: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 120,
                      width: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 40, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            
            // Book Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${book.author}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        book.rating > 0 ? book.rating.toStringAsFixed(1) : "N/A",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showStatusChangeDialog(book),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _getStatusColor(book.status),
                            side: BorderSide(color: _getStatusColor(book.status)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(_getStatusButtonText(book.status)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _getStatusButtonText(String status) {
    switch (status) {
      case 'want_to_read':
        return 'Want to Read';
      case 'currently_reading':
        return 'Currently Reading';
      case 'finished':
        return 'Finished';
      default:
        return 'Add to List';
    }
  }

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
}