import 'package:flutter/material.dart';
import '../models/discussion_details.dart';
import '../models/discussion_post.dart';

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
  
  final List<String> _categories = DiscussionUtils.getCategories();

  final List<DiscussionPost> _allPosts = [];
  final List<DiscussionPost> _myPosts = [];
  List<DiscussionPost> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadDiscussions();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      
      // Get sample posts from model class
      final samplePosts = DiscussionPost.getSamplePosts();
      
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
      // Use the filter method from DiscussionPost
      _filteredPosts = DiscussionPost.filterPosts(
        posts: currentList,
        categoryFilter: _selectedCategory,
      );
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterPosts();
  }

  void _navigateToPostDetails(DiscussionPost post) {
    // Navigate to post details screen with comments
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionDetailScreen(post: post),
      ),
    ).then((_) {
      setState(() {
        _filterPosts();
      });
    });
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
      // Use the model method instead of direct property manipulation
      post.toggleBookmark();
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
      // Use the model method
      post.like();
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
                    ? DiscussionUtils.buildEmptyState(
                        context: context,
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

  Widget _buildDiscussionsTab(List<DiscussionPost> posts) {
    return Column(
      children: [
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
              ? DiscussionUtils.buildEmptyState(
                  context: context,
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
              // Author info row - using utility method
              DiscussionUtils.buildAuthorRow(context, post.authorName, post.created),
              
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
              
              // Tags - using utility method
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DiscussionUtils.buildTagChips(context, post.tags),
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
  
  // Get available tags from utility class
  final List<String> _availableTags = DiscussionUtils.getAvailableTags();
  
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
    
    // Create new discussion post using factory method
    final newPost = DiscussionPost.createNew(
      title: _titleController.text,
      content: _contentController.text,
      tags: List.from(_selectedTags),
      authorId: 'currentUser',
      authorName: 'You',
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