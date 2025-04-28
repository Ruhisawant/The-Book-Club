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
    
    List<dynamic>? authorsList = volumeInfo['authors'] as List?;
    String authorName = 'Unknown Author';
    if (authorsList != null && authorsList.isNotEmpty) {
      authorName = authorsList.join(', ');
    }
    
    String? thumbnailUrl;
    if (volumeInfo['imageLinks'] != null) {
      thumbnailUrl = volumeInfo['imageLinks']['thumbnail'] as String?;
    }
    
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
  wantToRead, currentlyReading, finished,
}

extension ReadingStatusExtension on ReadingStatus {
  static const Map<ReadingStatus, String> _valueMap = {
    ReadingStatus.wantToRead: 'want_to_read',
    ReadingStatus.currentlyReading: 'currently_reading',
    ReadingStatus.finished: 'finished',
  };

  static const Map<ReadingStatus, String> _displayNameMap = {
    ReadingStatus.wantToRead: 'Want to Read',
    ReadingStatus.currentlyReading: 'Reading Now',
    ReadingStatus.finished: 'Finished',
  };

  static const Map<ReadingStatus, Color> _colorMap = {
    ReadingStatus.wantToRead: Colors.blue,
    ReadingStatus.currentlyReading: Colors.orange,
    ReadingStatus.finished: Colors.green,
  };

  String get value => _valueMap[this]!;
  String get displayName => _displayNameMap[this]!;
  Color get color => _colorMap[this]!;
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

// Book Data
class BookData {
  static const String _apiKey = 'AIzaSyCBUlM1xETefpbuj8GyuISrFlGa9m1QWbY';
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  
  static final BookData _instance = BookData._internal();
  factory BookData() => _instance;
  BookData._internal();
  
  final List<Book> _wantToReadBooks = [];
  final List<Book> _currentlyReadingBooks = [];
  final List<Book> _finishedBooks = [];
  
  List<Book> get wantToReadBooks => List.unmodifiable(_wantToReadBooks);
  List<Book> get currentlyReadingBooks => List.unmodifiable(_currentlyReadingBooks);
  List<Book> get finishedBooks => List.unmodifiable(_finishedBooks);
  
  List<Book> get allBooks {
    return [
      ..._wantToReadBooks,
      ..._currentlyReadingBooks,
      ..._finishedBooks,
    ];
  }
  
  // Update book status
  void updateBookStatus(Book book, dynamic newStatus) {
    String statusString = newStatus is ReadingStatus ? newStatus.value : newStatus;

    _wantToReadBooks.removeWhere((b) => b.id == book.id);
    _currentlyReadingBooks.removeWhere((b) => b.id == book.id);
    _finishedBooks.removeWhere((b) => b.id == book.id);

    book.status = statusString;

    switch (statusString) {
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
        _wantToReadBooks.add(book);
        break;
    }
  }
  
  // Get books by genre
  Future<List<Book>> getBooksByGenre(String genre) async {
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
        
        return books;
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      throw Exception('Error fetching recommendations: $e');
    }
  }
}

// LibraryBookCard Widget
class LibraryBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;
  final bool showGenreLabel;

  const LibraryBookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onStatusTap,
    this.showGenreLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final readingStatus = getStatusFromString(book.status);
    final statusColor = readingStatus.color;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.book, size: 60, color: Colors.grey),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.book, size: 60, color: Colors.grey),
                          ),
                    
                    // Status indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: onStatusTap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _getStatusIcon(book.status),
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Book info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Author
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Rating
                  if (book.rating > 0)
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}