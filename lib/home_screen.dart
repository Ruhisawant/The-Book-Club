import 'package:flutter/material.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double rating;
  String status; // "want_to_read", "currently_reading", "finished"

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.rating,
    required this.status,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Book> _books = [
    Book(
      id: '1',
      title: 'The Silent Patient',
      author: 'Alex Michaelides',
      coverUrl: 'https://example.com/book1.jpg',
      rating: 4.5,
      status: 'want_to_read',
    ),
    Book(
      id: '2',
      title: 'Atomic Habits',
      author: 'James Clear',
      coverUrl: 'https://example.com/book2.jpg',
      rating: 4.8,
      status: 'currently_reading',
    ),
    Book(
      id: '3',
      title: 'The Midnight Library',
      author: 'Matt Haig',
      coverUrl: 'https://example.com/book3.jpg',
      rating: 4.2,
      status: 'finished',
    ),
    Book(
      id: '4',
      title: 'Where the Crawdads Sing',
      author: 'Delia Owens',
      coverUrl: 'https://example.com/book4.jpg',
      rating: 4.7,
      status: 'want_to_read',
    ),
    Book(
      id: '5',
      title: 'Project Hail Mary',
      author: 'Andy Weir',
      coverUrl: 'https://example.com/book5.jpg',
      rating: 4.9,
      status: 'currently_reading',
    ),
    Book(
      id: '6',
      title: 'The Four Winds',
      author: 'Kristin Hannah',
      coverUrl: 'https://example.com/book6.jpg',
      rating: 4.6,
      status: 'finished',
    ),
  ];

  final List<Book> _recommendations = [
    Book(
      id: '7',
      title: 'Klara and the Sun',
      author: 'Kazuo Ishiguro',
      coverUrl: 'https://example.com/rec1.jpg',
      rating: 4.3,
      status: '',
    ),
    Book(
      id: '8',
      title: 'The Vanishing Half',
      author: 'Brit Bennett',
      coverUrl: 'https://example.com/rec2.jpg',
      rating: 4.4,
      status: '',
    ),
    Book(
      id: '9',
      title: 'Educated',
      author: 'Tara Westover',
      coverUrl: 'https://example.com/rec3.jpg',
      rating: 4.7,
      status: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeBookStatus(Book book, String newStatus) {
    setState(() {
      book.status = newStatus;
    });
  }

  void _viewBookDetails(Book book) {
    Navigator.pushNamed(
      context,
      '/book_details',
      arguments: book,
    );
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () => _viewBookDetails(book),
      child: Card(
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3/4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.book, size: 50, color: Colors.grey[600]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        book.rating.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (book.status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    _changeBookStatus(book, value);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'want_to_read',
                      child: Text('Want to Read'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'currently_reading',
                      child: Text('Currently Reading'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'finished',
                      child: Text('Finished'),
                    ),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          book.status == 'want_to_read'
                              ? 'Want to Read'
                              : book.status == 'currently_reading'
                                  ? 'Reading'
                                  : 'Finished',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Book> wantToReadBooks = _books.where((book) => book.status == 'want_to_read').toList();
    List<Book> currentlyReadingBooks = _books.where((book) => book.status == 'currently_reading').toList();
    List<Book> finishedBooks = _books.where((book) => book.status == 'finished').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('BookClub'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Want to Read'),
            Tab(text: 'Reading'),
            Tab(text: 'Finished'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Want to Read Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Books You Want to Read',
                  ),
                ),
                wantToReadBooks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'You haven\'t added any books to your "Want to Read" list yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: wantToReadBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(wantToReadBooks[index]);
                        },
                      ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Recommended for You',
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _recommendations.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 150,
                        margin: EdgeInsets.only(right: 16),
                        child: _buildBookCard(_recommendations[index]),
                      );
                    },
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
          
          // Currently Reading Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Books You\'re Reading',
                  ),
                ),
                currentlyReadingBooks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'You haven\'t added any books to your "Currently Reading" list yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: currentlyReadingBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(currentlyReadingBooks[index]);
                        },
                      ),
              ],
            ),
          ),
          
          // Finished Tab
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Books You\'ve Finished',
                  ),
                ),
                finishedBooks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'You haven\'t added any books to your "Finished" list yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(16),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: finishedBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(finishedBooks[index]);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/discussion');
              break;
            case 2:
              // Book search - placeholder
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Discussions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}