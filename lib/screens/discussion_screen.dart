import 'package:flutter/material.dart';

class DiscussionPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final DateTime created;
  int likes;
  int comments;
  final List<String> tags;
  bool isBookmarked;

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
    this.isBookmarked = false,
  });
}

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});
  
  @override
  State<DiscussionScreen> createState() => _DiscussionBoardsScreenState();
}

class _DiscussionBoardsScreenState extends State<DiscussionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
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

  final List<DiscussionPost> _allPosts = [];
  final List<DiscussionPost> _myPosts = [];
  List<DiscussionPost> _filteredPosts = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(_filterPosts);
    _loadDiscussions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _filterPosts();
      });
    }
  }

  Future<void> _loadDiscussions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulate loading data from a service
      await Future.delayed(const Duration(seconds: 1));
      
      // Sample data
      final samplePosts = [
        DiscussionPost(
          id: '1',
          authorId: 'user1',
          authorName: 'BookLover42',
          title: 'What did you think of the ending of Project Hail Mary?',
          content:
              'I just finished reading and I have so many thoughts! No spoilers in this post, but feel free to discuss in the comments.',
          created: DateTime.now().subtract(const Duration(hours: 3)),
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
          created: DateTime.now().subtract(const Duration(hours: 5)),
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
          created: DateTime.now().subtract(const Duration(days: 1)),
          likes: 18,
          comments: 23,
          tags: ['Mystery', 'Classics', 'Modern', 'Discussion'],
        ),
      ];
      
      setState(() {
        _allPosts.clear();
        _allPosts.addAll(samplePosts);
        
        // For demo purposes, let's add one post to "My Discussions"
        _myPosts.clear();
        _myPosts.add(samplePosts[0]);
        
        _filterPosts();
      });
    } catch (e) {
      debugPrint('Error loading discussions: $e');
      // Handle error state if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPosts() {
    final currentList = _tabController.index == 0 ? _allPosts : _myPosts;
    
    setState(() {
      final query = _searchController.text.toLowerCase();
      _filteredPosts = currentList.where((post) {
        // Filter by category
        if (_selectedCategory != 'All' && !post.tags.contains(_selectedCategory)) {
          return false;
        }
        
        // Filter by search query
        return query.isEmpty ||
            post.title.toLowerCase().contains(query) ||
            post.content.toLowerCase().contains(query) ||
            post.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            post.authorName.toLowerCase().contains(query);
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
        title: const Text('Feature Coming Soon'),
        content: const Text('Full post details will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        title: const Text('Feature Coming Soon'),
        content: const Text('Post creation will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark(DiscussionPost post) {
    setState(() {
      post.isBookmarked = !post.isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(post.isBookmarked 
          ? 'Discussion bookmarked' 
          : 'Bookmark removed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleLike(DiscussionPost post) {
    setState(() {
      // Toggle like status and update count
      // For simplicity, we're just increasing the count here
      post.likes += 1;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post liked'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Discussions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Discussions'),
            Tab(text: 'My Discussions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // All Discussions Tab
                _buildDiscussionsTab(_filteredPosts),
                
                // My Discussions Tab
                _myPosts.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.forum_outlined,
                        message: 'You haven\'t participated in any discussions yet',
                        buttonText: 'Start a Discussion',
                        onPressed: _createNewPost,
                      )
                    : _buildDiscussionsTab(_filteredPosts),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewPost,
        tooltip: 'Create New Discussion',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsTab(List<DiscussionPost> posts) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search discussions',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
        
        // Category selector
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor.withValues(),
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
          child: posts.isEmpty
              ? _buildEmptyState(
                  icon: Icons.forum_outlined,
                  message: 'No discussions found matching your criteria',
                  buttonText: 'Create Discussion',
                  onPressed: _createNewPost,
                )
              : RefreshIndicator(
                  onRefresh: _loadDiscussions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildDiscussionCard(posts[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDiscussionCard(DiscussionPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPostDetails(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author info row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      post.authorName[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTimeAgo(post.created),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Title and content
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[800]),
              ),
              
              const SizedBox(height: 16),
              
              // Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Theme.of(context).primaryColor.withValues(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () => _toggleLike(post),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_outlined, 
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            post.likes.toString(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Comments
                  InkWell(
                    onTap: () => _navigateToPostDetails(post),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.comment_outlined, 
                              size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            post.comments.toString(),
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Bookmark button
                  IconButton(
                    icon: Icon(
                      post.isBookmarked 
                          ? Icons.bookmark 
                          : Icons.bookmark_border,
                      color: post.isBookmarked 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[700],
                    ),
                    onPressed: () => _toggleBookmark(post),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}