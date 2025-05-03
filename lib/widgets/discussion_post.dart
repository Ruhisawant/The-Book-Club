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
  List<Comment> commentsList;

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
    this.commentsList = const [],
  });

  // Methods to encapsulate post-related business logic
  void toggleBookmark() {
    isBookmarked = !isBookmarked;
  }

  void like() {
    likes += 1;
  }

  void addComment(Comment comment) {
    commentsList.add(comment);
    comments = commentsList.length;
  }
  
  // For demo/sample data creation
  static List<DiscussionPost> getSamplePosts() {
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
    return [
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
  }
  
  // Factory method to create a new post from user input
  static DiscussionPost createNew({
    required String title,
    required String content,
    required List<String> tags,
    required String authorId,
    required String authorName,
  }) {
    return DiscussionPost(
      id: 'post-${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      title: title,
      content: content,
      created: DateTime.now(),
      likes: 0,
      comments: 0,
      tags: tags,
      commentsList: [],
    );
  }
  
  // Utility method to filter posts by criteria
  static List<DiscussionPost> filterPosts({
    required List<DiscussionPost> posts,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return posts.where((post) {
      // Filter by category
      if (categoryFilter != null && 
          categoryFilter != 'All' && 
          !post.tags.contains(categoryFilter)) {
        return false;
      }
      
      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return post.title.toLowerCase().contains(query) ||
               post.content.toLowerCase().contains(query) ||
               post.tags.any((tag) => tag.toLowerCase().contains(query)) ||
               post.authorName.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
}

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime created;
  int likes;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.created,
    this.likes = 0,
  });

  void like() {
    likes += 1;
  }
  
  // Create a new comment from user input
  static Comment createNew({
    required String content,
    required String authorId,
    required String authorName,
  }) {
    return Comment(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      authorName: authorName,
      content: content,
      created: DateTime.now(),
    );
  }
}

// Helper functions for UI displays
class DiscussionUtils {
  // Format the time difference between now and a past date
  static String getTimeAgo(DateTime dateTime) {
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
  
  // Common UI elements
  static Widget buildAuthorRow(BuildContext context, String authorName, DateTime created) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            authorName[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                getTimeAgo(created),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  static List<Widget> buildTagChips(BuildContext context, List<String> tags) {
    return tags.map((tag) {
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
    }).toList();
  }
  
  // Get all available categories for discussion posts
  static List<String> getCategories() {
    return [
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
  }
  
  // Get all available tags for creating posts
  static List<String> getAvailableTags() {
    return [
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
  }
  
  // Build empty state widget for reuse
  static Widget buildEmptyState({
    required BuildContext context,
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
}