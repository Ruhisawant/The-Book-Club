import 'package:flutter/material.dart';

class DiscussionPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final DateTime created;
  final int likes;
  final int comments;
  final List<String> tags;

  DiscussionPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.created,
    required this.likes,
    required this.comments,
    required this.tags,
  });
}

class DiscussionBoards extends StatefulWidget {
  const DiscussionBoards({super.key});
  @override
  DiscussionBoardsState createState() => DiscussionBoardsState();
}

class DiscussionBoardsState extends State<DiscussionBoards>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Fiction',
    'Non-fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Romance',
    'Horror',
    'Thriller',
    'Biography',
    'History',
  ];

  final List<DiscussionPost> _posts = [
    DiscussionPost(
      id: '1',
      authorId: 'user1',
      authorName: 'BookLover42',
      title: 'What did you think of the ending of Project Hail Mary?',
      content:
          'I just finished reading and I have so many thoughts! No spoilers in this post, but feel free to discuss in the comments.',
      created: DateTime.now().subtract(Duration(hours: 3)),
      likes: 24,
      comments: 15,
      tags: ['Science Fiction', 'Andy Weir', 'Project Hail Mary'],
    ),
    DiscussionPost(
      id: '2',
      authorId: 'user2',
      authorName: 'LiteraryExplorer',
      title: 'Best fantasy series for someone new to the genre?',
      content:
          'I\'ve mostly read literary fiction but want to try fantasy. Looking for recommendations that aren\'t too dense or complex for a beginner.',
      created: DateTime.now().subtract(Duration(hours: 5)),
      likes: 36,
      comments: 42,
      tags: ['Fantasy', 'Recommendations', 'Beginner'],
    ),
    DiscussionPost(
      id: '3',
      authorId: 'user3',
      authorName: 'MysteryFan',
      title: 'Classic vs. Modern Mystery Novels: What\'s your preference?',
      content:
          'Do you prefer Agatha Christie style mysteries or more modern psychological thrillers? I\'m curious about what people enjoy about each style.',
      created: DateTime.now().subtract(Duration(days: 1)),
      likes: 18,
      comments: 23,
      tags: ['Mystery', 'Classics', 'Modern', 'Discussion'],
    ),
    DiscussionPost(
      id: '4',
      authorId: 'user4',
      authorName: 'HistoryBuff',
      title: 'Most accurate historical fiction recommendations?',
      content:
          'I love historical fiction but sometimes the historical accuracy can be questionable. Looking for recommendations of novels that really get the history right.',
      created: DateTime.now().subtract(Duration(days: 2)),
      likes: 29,
      comments: 17,
      tags: ['Historical Fiction', 'Recommendations', 'Accuracy'],
    ),
    DiscussionPost(
      id: '5',
      authorId: 'user5',
      authorName: 'SciFiEnthusiast',
      title: 'Underrated sci-fi from the last decade',
      content:
          'We all know the big names, but what are some lesser-known sci-fi gems from the past ten years that deserve more attention?',
      created: DateTime.now().subtract(Duration(days: 3)),
      likes: 42,
      comments: 31,
      tags: ['Science Fiction', 'Underrated', 'Recommendations'],
    ),
    DiscussionPost(
      id: '6',
      authorId: 'user6',
      authorName: 'RomanceReader',
      title: 'Romance novels with strong character development',
      content:
          'Looking for romance novels where the characters have real depth and growth throughout the story, not just a focus on the relationship.',
      created: DateTime.now().subtract(Duration(days: 4)),
      likes: 33,
      comments: 27,
      tags: ['Romance', 'Character Development', 'Recommendations'],
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<DiscussionPost> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredPosts = List.from(_posts);
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterPosts() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredPosts = _posts.where((post) {
        // Filter by category
        if (_selectedCategory != 'All' &&
            !post.tags.contains(_selectedCategory)) {
          return false;
        }
        // Filter by search query
        return query.isEmpty ||
            post.title.toLowerCase().contains(query) ||
            post.content.toLowerCase().contains(query) ||
            post.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterPosts();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToPostDetails(DiscussionPost post) {
    // Navigate to post details screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feature Coming Soon'),
        content: Text('Full post details will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _createNewPost() {
    // Navigate to create post screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Feature Coming Soon'),
        content: Text('Post creation will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discussions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All Discussions'),
            Tab(text: 'My Discussions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Discussions Tab
          _buildDiscussionsTab(),
          
          // My Discussions Tab
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'You haven\'t participated in any discussions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _createNewPost,
                  child: Text('Start a Discussion'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewPost,
        tooltip: 'Create New Discussion',
        child: Icon(Icons.add),
      ),
      // Bottom navigation bar removed as it's now handled by Navigation widget
    );
  }

  Widget _buildDiscussionsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search discussions',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        // Category selector
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _selectCategory(category);
                    }
                  },
                ),
              );
            },
          ),
        ),
        // Discussion posts
        Expanded(
          child: _filteredPosts.isEmpty
              ? Center(
                  child: Text(
                    'No discussions found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = _filteredPosts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: InkWell(
                        onTap: () => _navigateToPostDetails(post),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.indigo,
                                    child: Text(
                                      post.authorName[0],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _getTimeAgo(post.created),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                post.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                post.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                children: post.tags.map((tag) {
                                  return Chip(
                                    label: Text(
                                      tag,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up_outlined,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    post.likes.toString(),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(width: 16),
                                  Icon(Icons.comment_outlined,
                                      size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    post.comments.toString(),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    icon: Icon(Icons.bookmark_border),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}