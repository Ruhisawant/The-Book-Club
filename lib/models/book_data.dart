import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Book Model
class Book {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final double rating;
  String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.rating = 4.0,
    this.status = 'want_to_read',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'];
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: (volumeInfo['authors'] as List?)?.first ?? 'Unknown Author',
      coverUrl: volumeInfo['imageLinks']?['thumbnail'],
      rating: (volumeInfo['averageRating'] != null) 
          ? (volumeInfo['averageRating'] as num).toDouble() 
          : 4.0,
      status: 'want_to_read',
    );
  }
}

// Book Data Service
class BookData {
  static const String _apiKey = 'AIzaSyCBUlM1xETefpbuj8GyuISrFlGa9m1QWbY';
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  // Singleton instance
  static final BookData _instance = BookData._internal();
  
  // Factory constructor
  factory BookData() => _instance;
  
  // Internal constructor
  BookData._internal();
  
  // User's book lists
  final List<Book> _wantToReadBooks = [];
  final List<Book> _currentlyReadingBooks = [];
  final List<Book> _finishedBooks = [];
  
  // Getters for the book lists
  List<Book> get wantToReadBooks => List.unmodifiable(_wantToReadBooks);
  List<Book> get currentlyReadingBooks => List.unmodifiable(_currentlyReadingBooks);
  List<Book> get finishedBooks => List.unmodifiable(_finishedBooks);
  
  // Get all books from all lists
  List<Book> get allBooks {
    final List<Book> books = [];
    books.addAll(_wantToReadBooks);
    books.addAll(_currentlyReadingBooks);
    books.addAll(_finishedBooks);
    return books;
  }
  
  // Loading flag
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Search Books from Google Books API
  Future<List<Book>> searchBooks(String query, {int page = 1, int limit = 40, int startIndex = 0}) async {
  if (query.isEmpty) return [];

  _isLoading = true;
  
  // If page parameter is provided, calculate startIndex
  if (startIndex == 0 && page > 1) {
    startIndex = (page - 1) * limit;
  }

  try {
    final response = await http.get(
      Uri.parse('$_baseUrl?q=$query&startIndex=$startIndex&maxResults=$limit&key=$_apiKey')
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List?;

      if (items == null) return [];

      final books = items.map((item) => Book.fromJson(item)).toList();

      for (var book in books) {
        final existingBook = findBookById(book.id);
        if (existingBook != null) {
          book.status = existingBook.status;
        }
      }

      return books;
    }
  } catch (e) {
    debugPrint('Error searching books: $e');
  } finally {
    _isLoading = false;
  }

  return [];
}
  
  // Get book by ID
  Book? findBookById(String id) {
    for (var book in allBooks) {
      if (book.id == id) return book;
    }
    return null;
  }
  
  // Update book status
  void updateBookStatus(Book book, String newStatus) {
    // Remove from current list
    _wantToReadBooks.removeWhere((b) => b.id == book.id);
    _currentlyReadingBooks.removeWhere((b) => b.id == book.id);
    _finishedBooks.removeWhere((b) => b.id == book.id);
    
    // Update status
    book.status = newStatus;
    
    // Add to new list
    switch (newStatus) {
      case 'want_to_read':
        _wantToReadBooks.add(book);
        break;
      case 'currently_reading':
        _currentlyReadingBooks.add(book);
        break;
      case 'finished':
        _finishedBooks.add(book);
        break;
    }
  }
  
  // Get trending books (example)
  Future<List<Book>> getTrendingBooks() async {
    const query = 'subject:fiction&orderBy=newest';
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&maxResults=10&key=$_apiKey')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching trending books: $e');
    }
    
    return [];
  }
  
  // Get book recommendations based on a genre
  Future<List<Book>> getRecommendedBooks(String genre) async {
    final query = 'subject:$genre';
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&maxResults=10&key=$_apiKey')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
    }
    
    return [];
  }
  
  // Initialize with some sample data
  Future<void> initializeWithSampleData() async {
    if (allBooks.isNotEmpty) return;
    
    final samples = await searchBooks('bestsellers fiction');
    
    // Add some books to different lists
    if (samples.isNotEmpty) {
      for (int i = 0; i < samples.length; i++) {
        if (i < 3) {
          updateBookStatus(samples[i], 'want_to_read');
        } else if (i < 6) {
          updateBookStatus(samples[i], 'currently_reading');
        } else if (i < 9) {
          updateBookStatus(samples[i], 'finished');
        }
      }
    }
  }
}

// BookCard widget
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;

  const BookCard({
    required this.book,
    required this.onTap,
    required this.onStatusTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor(String status) {
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

    String getStatusText(String status) {
      switch (status) {
        case 'want_to_read':
          return 'Want to Read';
        case 'currently_reading':
          return 'Reading Now';
        case 'finished':
          return 'Finished';
        default:
          return 'Add to List';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      softWrap: true,
                      overflow: TextOverflow.fade,
                    ),
                    SizedBox(height: 2),
                    // Author
                    Text(
                      book.author,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      softWrap: true,
                      overflow: TextOverflow.fade,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        SizedBox(width: 2),
                        Text(
                          book.rating.toString(),
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
                child: InkWell(
                  onTap: onStatusTap,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: getStatusColor(book.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusText(book.status),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}