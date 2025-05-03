import 'package:flutter/material.dart';
import '../models/discussion_post.dart';

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
    
    // Create a new comment using the factory method
    final newComment = Comment.createNew(
      content: _commentController.text,
      authorId: 'currentUser',
      authorName: 'You',
    );
    
    setState(() {
      // Add the comment to the post using the model method
      widget.post.addComment(newComment);
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
      // Use the model method
      comment.like();
    });
  }
  
  void _likePost() {
    setState(() {
      // Use the model method
      widget.post.like();
    });
  }

  void _toggleBookmark() {
    setState(() {
      // Use the model method
      widget.post.toggleBookmark();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.post.isBookmarked 
            ? 'Discussion bookmarked' 
            : 'Bookmark removed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Details'),
        actions: [
          IconButton(
            icon: Icon(
              widget.post.isBookmarked 
                  ? Icons.bookmark 
                  : Icons.bookmark_border,
              color: widget.post.isBookmarked 
                  ? Theme.of(context).primaryColor 
                  : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
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
                  // Author info - using utility method
                  DiscussionUtils.buildAuthorRow(context, widget.post.authorName, widget.post.created),
                  
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
                  
                  // Tags - using utility method
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DiscussionUtils.buildTagChips(context, widget.post.tags),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Like button
                      OutlinedButton.icon(
                        onPressed: _likePost,
                        icon: const Icon(Icons.thumb_up_outlined),
                        label: Text('Like (${widget.post.likes})'),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Share button
                      OutlinedButton.icon(
                        onPressed: () {
                          // Implementation for sharing functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share functionality will be implemented soon')),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  // Comments section
                  Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.post.comments}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Comments list
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          
          // Add comment section
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (widget.post.commentsList.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.post.commentsList.length,
      itemBuilder: (context, index) {
        final comment = widget.post.commentsList[index];
        return _buildCommentCard(comment);
      },
    );
  }

  Widget _buildCommentCard(Comment comment) {
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
                      DiscussionUtils.getTimeAgo(comment.created),
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
                // Option to add reply button here
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
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
    );
  }
}