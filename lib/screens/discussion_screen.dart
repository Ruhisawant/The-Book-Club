import 'package:flutter/material.dart';
import '../widgets/discussion_post.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});
  
  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen>
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
      
      // Sample comments for posts
      final sampleComments = [
        Comment(
          id: 'c1',
          authorId: 'user5',
          authorName: 'SciFiEnthusiast',
          content: 'The ending completely blew my mind! I didn\'t see it coming at all.',
          created: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 7,
        ),
        Comment(
          id: 'c2',
          authorId: 'user6',
          authorName: 'BookDragon',
          content: 'I loved how the characters developed throughout the story. Amazing character arcs!',
          created: DateTime.now().subtract(const Duration(hours: 1)),
          likes: 4,
        ),
        Comment(
          id: 'c3',
          authorId: 'user7',
          authorName: 'SpaceExplorer',
          content: 'The science was surprisingly accurate too. I appreciated the research that went into it.',
          created: DateTime.now().subtract(const Duration(minutes: 30)),
          likes: 2,
        ),
      ];
      
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
          comments: 3,
          tags: ['Science Fiction', 'Andy Weir', 'Project Hail Mary'],
          commentsList: sampleComments,
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
          commentsList: [
            Comment(
              id: 'c4',
              authorId: 'user8',
              authorName: 'FantasyReader',
              content: 'The Mistborn series by Brandon Sanderson is a great entry point!',
              created: DateTime.now().subtract(const Duration(hours: 4)),
              likes: 15,
            ),
            Comment(
              id: 'c5',
              authorId: 'user9',
              authorName: 'BookWizard',
              content: 'Try "The Name of the Wind" by Patrick Rothfuss. It\'s beautifully written.',
              created: DateTime.now().subtract(const Duration(hours: 3)),
              likes: 10,
            ),
          ],
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
          commentsList: [
            Comment(
              id: 'c6',
              authorId: 'user10',
              authorName: 'DetectiveBookworm',
              content: 'I love classic mysteries! The intricate plotting in Christie\'s works is unmatched.',
              created: DateTime.now().subtract(const Duration(hours: 20)),
              likes: 8,
            ),
          ],
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
    // Navigate to post details screen with comments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(post: post),
      ),
    );
  }

  void _createNewPost() {
    // Navigate to create post screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDiscussionScreen(
          onPostCreated: (newPost) {
            setState(() {
              _allPosts.insert(0, newPost);
              _myPosts.insert(0, newPost);
              _filterPosts();
            });
          },
        ),
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
        automaticallyImplyLeading: false,
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
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
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
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
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

// New screens for implementing the requested features
class DiscussionDetailScreen extends StatefulWidget {
  final DiscussionPost post;
  
  const DiscussionDetailScreen({super.key, required this.post});
  
  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  void _addComment() {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    
    final newComment = Comment(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'currentUser', // In a real app, this would be the current user's ID
      authorName: 'You', // In a real app, this would be the current user's name
      content: _commentController.text,
      created: DateTime.now(),
    );
    
    setState(() {
      widget.post.commentsList.add(newComment);
      widget.post.comments = widget.post.commentsList.length;
      _commentController.clear();
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment added'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _likeComment(Comment comment) {
    setState(() {
      comment.likes += 1;
    });
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Details'),
      ),
      body: Column(
        children: [
          // Post details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          widget.post.authorName[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getTimeAgo(widget.post.created),
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
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content
                  Text(
                    widget.post.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.post.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Like button
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            widget.post.likes += 1;
                          });
                        },
                        icon: const Icon(Icons.thumb_up_outlined),
                        label: Text('Like (${widget.post.likes})'),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Bookmark button
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            widget.post.isBookmarked = !widget.post.isBookmarked;
                          });
                        },
                        icon: Icon(
                          widget.post.isBookmarked 
                              ? Icons.bookmark 
                              : Icons.bookmark_border,
                        ),
                        label: Text(
                          widget.post.isBookmarked ? 'Bookmarked' : 'Bookmark',
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  // Comments section
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Comments list
                  widget.post.commentsList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.post.commentsList.length,
                          itemBuilder: (context, index) {
                            final comment = widget.post.commentsList[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Comment author info
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            comment.authorName[0],
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment.authorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              _getTimeAgo(comment.created),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Comment content
                                    Text(comment.content),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Like button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _likeComment(comment),
                                          icon: const Icon(Icons.thumb_up_outlined, size: 16),
                                          label: Text(
                                            comment.likes > 0 ? comment.likes.toString() : 'Like',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // Add comment section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateDiscussionScreen extends StatefulWidget {
  final Function(DiscussionPost) onPostCreated;
  
  const CreateDiscussionScreen({
    super.key, 
    required this.onPostCreated,
  });
  
  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<String> _selectedTags = [];
  
  final List<String> _availableTags = [
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
    'Book Club',
    'Recommendations',
    'Discussion',
    'Review',
    'Series',
    'Classic',
    'Modern',
    'Beginner',
  ];
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return false;
    }
    
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return false;
    }
    
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return false;
    }
    
    return true;
  }
  
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }
  
  void _submitPost() {
    if (!_validateForm()) {
      return;
    }
    
    // Create new discussion post
    final newPost = DiscussionPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'currentUser', // In a real app, this would be the current user's ID
      authorName: 'You', // In a real app, this would be the current user's name
      title: _titleController.text,
      content: _contentController.text,
      created: DateTime.now(),
      likes: 0,
      comments: 0,
      tags: List.from(_selectedTags),
      commentsList: [],
    );
    
    // Call the callback
    widget.onPostCreated(newPost);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Discussion posted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Return to previous screen
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Discussion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for your discussion',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            
            const SizedBox(height: 16),
            
            // Content field
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your thoughts here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tags section
            const Text(
              'Select Tags (at least one):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, 
              ),
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => _toggleTag(tag),
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Post Discussion',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}