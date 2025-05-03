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
}