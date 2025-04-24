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
    this.rating = 0.0,
    this.status = 'want_to_read',
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    
    // Handle author list properly
    List<dynamic>? authorsList = volumeInfo['authors'] as List?;
    String authorName = 'Unknown Author';
    if (authorsList != null && authorsList.isNotEmpty) {
      authorName = authorsList.join(', ');
    }
    
    // Handle cover image with null safety
    String? thumbnailUrl;
    if (volumeInfo['imageLinks'] != null) {
      thumbnailUrl = volumeInfo['imageLinks']['thumbnail'] as String?;
    }
    
    // Handle ratings
    double bookRating = 0.0;
    if (volumeInfo['averageRating'] != null) {
      bookRating = (volumeInfo['averageRating'] as num).toDouble();
    }
    
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      author: authorName,
      coverUrl: thumbnailUrl,
      rating: bookRating,
      status: 'want_to_read',
    );
  }
  
  // Add toMap method for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'rating': rating,
      'status': status,
    };
  }
}

// ReadingStatus enum for better type safety
enum ReadingStatus {
  wantToRead,
  currentlyReading,
  finished,
}

extension ReadingStatusExtension on ReadingStatus {
  String get value {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'want_to_read';
      case ReadingStatus.currentlyReading:
        return 'currently_reading';
      case ReadingStatus.finished:
        return 'finished';
    }
  }
  
  String get displayName {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.currentlyReading:
        return 'Reading Now';
      case ReadingStatus.finished:
        return 'Finished';
    }
  }
  
  Color get color {
    switch (this) {
      case ReadingStatus.wantToRead:
        return Colors.blue;
      case ReadingStatus.currentlyReading:
        return Colors.orange;
      case ReadingStatus.finished:
        return Colors.green;
    }
  }
}

// Convert string status to enum
ReadingStatus getStatusFromString(String status) {
  switch (status) {
    case 'currently_reading':
      return ReadingStatus.currentlyReading;
    case 'finished':
      return ReadingStatus.finished;
    case 'want_to_read':
    default:
      return ReadingStatus.wantToRead;
  }
}

// Book Data Service with improved error handling and organization
class BookData {
  // API constants
  static const String _apiKey = 'AIzaSyCBUlM1xETefpbuj8GyuISrFlGa9m1QWbY';
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  // Singleton pattern
  static final BookData _instance = BookData._internal();
  factory BookData() => _instance;
  BookData._internal();
  
  // User's book lists with better naming
  final List<Book> _wantToReadBooks = [];
  final List<Book> _currentlyReadingBooks = [];
  final List<Book> _finishedBooks = [];
  
  // Getters with unmodifiable views
  List<Book> get wantToReadBooks => List.unmodifiable(_wantToReadBooks);
  List<Book> get currentlyReadingBooks => List.unmodifiable(_currentlyReadingBooks);
  List<Book> get finishedBooks => List.unmodifiable(_finishedBooks);
  
  // Combined books getter with better performance
  List<Book> get allBooks {
    return [
      ..._wantToReadBooks,
      ..._currentlyReadingBooks,
      ..._finishedBooks,
    ];
  }
  
  // Loading state with notifier
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Search Books with improved error handling
  Future<List<Book>> searchBooks(String query, {
    int page = 1, 
    int limit = 40, 
    int startIndex = 0,
    bool includeStatusCheck = true,
  }) async {
    if (query.isEmpty) return [];

    _isLoading = true;
    
    // Calculate startIndex based on page if needed
    if (startIndex == 0 && page > 1) {
      startIndex = (page - 1) * limit;
    }

    try {
      final Uri uri = Uri.parse('$_baseUrl?q=$query&startIndex=$startIndex&maxResults=$limit&key=$_apiKey');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;

        if (items == null || items.isEmpty) return [];

        final books = items.map((item) => Book.fromJson(item)).toList();

        // Check if books are already in user lists
        if (includeStatusCheck) {
          for (var book in books) {
            final existingBook = findBookById(book.id);
            if (existingBook != null) {
              book.status = existingBook.status;
            }
          }
        }

        return books;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching books: $e');
      throw Exception('Error searching books: $e');
    } finally {
      _isLoading = false;
    }
  }
  
  // Find book by ID with improved search
  Book? findBookById(String id) {
    // First check want to read list
    final wantToReadBook = _wantToReadBooks.where((b) => b.id == id).firstOrNull;
    if (wantToReadBook != null) return wantToReadBook;
    
    // Then check currently reading list
    final currentlyReadingBook = _currentlyReadingBooks.where((b) => b.id == id).firstOrNull;
    if (currentlyReadingBook != null) return currentlyReadingBook;
    
    // Finally check finished list
    return _finishedBooks.where((b) => b.id == id).firstOrNull;
  }
  
  // Update book status with enum support
  void updateBookStatus(Book book, String newStatus) {
    // Remove from all lists
    _wantToReadBooks.removeWhere((b) => b.id == book.id);
    _currentlyReadingBooks.removeWhere((b) => b.id == book.id);
    _finishedBooks.removeWhere((b) => b.id == book.id);
    
    // Update status
    book.status = newStatus;
    
    // Add to appropriate list
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
      default:
        // Handle invalid status
        debugPrint('Warning: Invalid book status: $newStatus');
        _wantToReadBooks.add(book);
        break;
    }
  }
  
  // Update book status with enum
  void updateBookStatusWithEnum(Book book, ReadingStatus newStatus) {
    updateBookStatus(book, newStatus.value);
  }
  
  // Get trending books with improved error handling
  Future<List<Book>> getTrendingBooks() async {
    const query = 'subject:fiction&orderBy=newest';
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&maxResults=10&key=$_apiKey')
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items == null || items.isEmpty) return [];
        
        final books = items.map((item) => Book.fromJson(item)).toList();
        
        // Check if books are already in user lists
        for (var book in books) {
          final existingBook = findBookById(book.id);
          if (existingBook != null) {
            book.status = existingBook.status;
          }
        }
        
        return books;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load trending books');
      }
    } catch (e) {
      debugPrint('Error fetching trending books: $e');
      throw Exception('Error fetching trending books: $e');
    }
  }
  
  // Get book recommendations with improved implementation
  Future<List<Book>> getRecommendedBooks(String genre) async {
    // Sanitize input
    final sanitizedGenre = genre.trim().toLowerCase().replaceAll(' ', '-');
    final query = 'subject:$sanitizedGenre';
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&maxResults=10&key=$_apiKey')
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items == null || items.isEmpty) return [];
        
        final books = items.map((item) => Book.fromJson(item)).toList();
        
        // Check if books are already in user lists
        for (var book in books) {
          final existingBook = findBookById(book.id);
          if (existingBook != null) {
            book.status = existingBook.status;
          }
        }
        
        return books;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      throw Exception('Error fetching recommendations: $e');
    }
  }
  
  // Initialize with sample data with better error handling
  Future<void> initializeWithSampleData() async {
    if (allBooks.isNotEmpty) return;
    
    try {
      final samples = await searchBooks('bestsellers fiction', includeStatusCheck: false);
      
      // Add some books to different lists
      if (samples.isNotEmpty) {
        for (int i = 0; i < samples.length && i < 9; i++) {
          if (i < 3) {
            updateBookStatus(samples[i], ReadingStatus.wantToRead.value);
          } else if (i < 6) {
            updateBookStatus(samples[i], ReadingStatus.currentlyReading.value);
          } else {
            updateBookStatus(samples[i], ReadingStatus.finished.value);
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
      // Fallback with empty lists is fine here
    }
  }
  
  // Clear all books (useful for testing or logout)
  void clearAllBooks() {
    _wantToReadBooks.clear();
    _currentlyReadingBooks.clear();
    _finishedBooks.clear();
  }
}

// Improved BookCard widget with better styling and responsiveness
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
    // Convert string status to enum for better type safety
    final status = getStatusFromString(book.status);
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover image (if available)
              if (book.coverUrl != null)
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.book, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.book, color: Colors.grey),
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Book Info Section
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Author
                    Text(
                      book.author,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating
                    if (book.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Status Button
              InkWell(
                onTap: onStatusTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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