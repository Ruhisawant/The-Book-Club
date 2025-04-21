import 'package:flutter/material.dart';
import '/models/book_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookData _bookData = BookData();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_bookData.allBooks.isEmpty) {
        await _bookData.initializeWithSampleData();
      }
    } catch (e) {
      Text('Error loading initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeBookStatus(Book book, String newStatus) {
    setState(() {
      _bookData.updateBookStatus(book, newStatus);
    });
  }

  void _viewBookDetails(Book book) {
    Navigator.pushNamed(
      context,
      '/book_details',
      arguments: book,
    );
  }

  void _showStatusMenu(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.bookmark_border),
                title: Text('Want to Read'),
                onTap: () {
                  _changeBookStatus(book, 'want_to_read');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.auto_stories),
                title: Text('Currently Reading'),
                onTap: () {
                  _changeBookStatus(book, 'currently_reading');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text('Finished'),
                onTap: () {
                  _changeBookStatus(book, 'finished');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookList(List<Book> books, String emptyMessage) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return books.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              emptyMessage,
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
          itemCount: books.length,
          itemBuilder: (context, index) {
            return BookCard(
              book: books[index],
              onTap: () => _viewBookDetails(books[index]),
              onStatusTap: () => _showStatusMenu(context, books[index]),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BookClub'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildBookList(
                  _bookData.wantToReadBooks,
                  'You haven\'t added any books to your "Want to Read" list yet.'
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildBookList(
                  _bookData.currentlyReadingBooks,
                  'You haven\'t added any books to your "Currently Reading" list yet.'
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
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildBookList(
                  _bookData.finishedBooks,
                  'You haven\'t added any books to your "Finished" list yet.'
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
              break;
            case 1:
              Navigator.pushNamed(context, '/discussion');
              break;
            case 2:
              Navigator.pushNamed(context, '/library');
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
            icon: Icon(Icons.library_books),
            label: 'Library',
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