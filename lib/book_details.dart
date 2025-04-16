import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class BookDetails extends StatefulWidget {
  final Map<String, dynamic>? bookData;
  
  const BookDetails({super.key, required this.bookData});

  @override
  BookDetailsState createState() => BookDetailsState();
}

class BookDetailsState extends State<BookDetails> {
  String _selectedReadingStatus = 'Want to Read';
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoadingAISummary = false;
  String _aiSummary = '';
  
  final List<Map<String, dynamic>> _communityReviews = [
    {
      'username': 'bookworm42',
      'rating': 4.5,
      'review': 'This book changed my perspective on so many things. Highly recommended!',
      'date': '2 days ago',
      'likes': 24,
    },
    {
      'username': 'literarylover',
      'rating': 3.0,
      'review': 'Decent read but the character development felt rushed.',
      'date': '1 week ago',
      'likes': 7,
    },
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _getAISummary() {
    setState(() {
      _isLoadingAISummary = true;
    });
    
    // Simulating API call delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _aiSummary = 'Readers generally praised the narrative structure and character development, though some felt the ending was predictable. Most appreciated the author\'s attention to historical detail and atmospheric setting. Common criticisms include pacing issues in the middle section and some underdeveloped side characters.';
        _isLoadingAISummary = false;
      });
    });
  }

  void _submitReview() {
    if (_reviewController.text.isNotEmpty && _userRating > 0) {
      // Here you would normally send to backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );
      _reviewController.clear();
      setState(() {
        _userRating = 0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add both rating and review text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock data if no book data is provided
    final bookData = widget.bookData ?? {
      'title': 'The Silent Echo',
      'author': 'Alexandra Rivers',
      'coverUrl': 'https://example.com/book-cover.jpg',
      'rating': 4.2,
      'ratingCount': 1287,
      'description': 'A gripping tale of mystery and redemption set in a small coastal town where secrets run as deep as the ocean. When protagonist Emily returns to her childhood home after twenty years, she uncovers truths that challenge everything she thought she knew about her family.',
      'genres': ['Mystery', 'Drama', 'Contemporary Fiction'],
      'pageCount': 342,
      'publishDate': 'March 15, 2023',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover and Basic Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(child: Icon(Icons.book, size: 50)),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookData['title'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'by ${bookData['author']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              '${bookData['rating']} (${bookData['ratingCount']} ratings)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: (bookData['genres'] as List)
                              .map((genre) => Chip(
                                    label: Text(genre),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: TextStyle(fontSize: 12),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Reading Status Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reading Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedReadingStatus,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedReadingStatus = newValue;
                            });
                          }
                        },
                        items: <String>[
                          'Want to Read',
                          'Currently Reading',
                          'Finished',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status updated to $_selectedReadingStatus')),
                            );
                          },
                          child: Text('Update Status'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Book Description
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    bookData['description'],
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Pages: ${bookData['pageCount']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Published: ${bookData['publishDate']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // AI Summary Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AI Summary of Reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_aiSummary.isEmpty && !_isLoadingAISummary)
                            TextButton(
                              onPressed: _getAISummary,
                              child: Text('Generate'),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (_isLoadingAISummary)
                        Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_aiSummary.isNotEmpty)
                        Text(
                          _aiSummary,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        )
                      else
                        Text(
                          'Click "Generate" to see an AI-powered summary of reader reviews.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Write a Review Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Write a Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text('Your Rating'),
                      SizedBox(height: 8),
                      RatingBar.builder(
                        initialRating: _userRating,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 30,
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _userRating = rating;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _reviewController,
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts about this book...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReview,
                          child: Text('Submit Review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Community Reviews Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Reviews',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ..._communityReviews.map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review['username'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      review['date'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < review['rating']
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                SizedBox(height: 8),
                                Text(review['review']),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.thumb_up_outlined, size: 16),
                                    SizedBox(width: 4),
                                    Text('${review['likes']}'),
                                    SizedBox(width: 16),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            
            // Recommended Books Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You Might Also Like',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Icon(Icons.book)),
                              ),
                              SizedBox(height: 4),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Book Title ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Author ${index + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}