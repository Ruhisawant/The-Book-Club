import 'package:flutter/material.dart';
import '/models/book_data.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  
  @override
  LibraryScreenState createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  String _currentFilter = 'All Books';
  final BookData _bookService = BookData();
  List<Book> _displayedBooks = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _limit = 20;
  final List<Book> _recommendations = [];
  final List<String> _categories = [
    'All Books', 'Fiction', 'Non-Fiction', 'Mystery', 'Science Fiction', 
    'Fantasy', 'Biography', 'Self-Help', 'Romance', 'Thriller'
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadRecommendations();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _displayedBooks = [];
      _currentPage = 1;
    });

    try {
      final books = await _bookService.searchBooks('bestsellers', startIndex: 0, limit: 40);
      
      for (int i = 0; i < books.length; i++) {
        if (i < 10) {
          _bookService.updateBookStatus(books[i], 'want_to_read');
        } else if (i < 20) {
          _bookService.updateBookStatus(books[i], 'currently_reading');
        } else if (i < 30) {
          _bookService.updateBookStatus(books[i], 'finished');
        }
      }
      
      setState(() {
        _displayedBooks = books;
      });
    } catch (e) {
      Text('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDisplayedBooks() {
    setState(() {
      _displayedBooks = [];
      _currentPage = 1;
    });

    _fetchBooksByFilter(_currentFilter);
  }

  Future<void> _fetchBooksByFilter(String filter) async {
    setState(() {
      _isLoading = true;
    });

    String query;
    if (filter == 'All Books') {
      query = 'bestsellers';
    } else {
      query = 'subject:$filter';
    }

    try {
      final books = await _bookService.searchBooks(query, page: _currentPage, limit: _limit);
      setState(() {
        _displayedBooks = books;
      });
    } catch (e) {
      Text('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    _currentPage++;

    String query;
    if (_currentFilter == 'All Books') {
      query = 'bestsellers';
    } else {
      query = 'subject:$_currentFilter';
    }

    try {
      final moreBooks = await _bookService.searchBooks(query, page: _currentPage, limit: _limit);
      
      if (moreBooks.isNotEmpty) {
        setState(() {
          _displayedBooks.addAll(moreBooks);
        });
      } else {
        _currentPage--;
        Text('No more books to load');
      }
    } catch (e) {
      _currentPage--;
      Text('Error loading more books: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recBooks = await _bookService.searchBooks('recommended', startIndex: 0, limit: 10);
      setState(() {
        _recommendations.addAll(recBooks);
      });
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Library'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search not implemented yet')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _currentFilter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFilter = category;
                      _displayedBooks.clear();
                      _currentPage = 1;
                      _updateDisplayedBooks();
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recommended for You',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SizedBox(
              height: 300,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _recommendations.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 150,
                    margin: EdgeInsets.only(right: 16),
                    child: BookCard(
                      book: _recommendations[index],
                      onTap: () => _viewBookDetails(_recommendations[index]),
                      onStatusTap: () {},
                    ),
                  );
                },
              ),
            ),
          // Book grid
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'All',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _displayedBooks.isEmpty
                          ? Center(
                              child: Text(
                                'No books found',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadBooks,
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (scrollNotification) {
                                  if (scrollNotification is ScrollUpdateNotification &&
                                      scrollNotification.metrics.pixels ==
                                          scrollNotification.metrics.maxScrollExtent) {
                                    _loadMoreBooks();
                                    return true;
                                  }
                                  return false;
                                },
                                child: GridView.builder(
                                  padding: EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    childAspectRatio: 0.55,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _displayedBooks.length,
                                  itemBuilder: (context, index) {
                                    return BookCard(
                                      book: _displayedBooks[index],
                                      onTap: () => _viewBookDetails(_displayedBooks[index]),
                                      onStatusTap: () {},
                                    );
                                  },
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      
    );
  }

  void _viewBookDetails(Book book) {
    Navigator.pushNamed(context, '/book_details', arguments: book);
  }
}
