import 'package:supabase_flutter/supabase_flutter.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final String? parentId;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      parentId: json['parent_id'],
    );
  }
}

class CommentWithAuthor {
  final Comment comment;
  final String authorName;
  final String? authorAvatarUrl;

  CommentWithAuthor({
    required this.comment,
    required this.authorName,
    this.authorAvatarUrl,
  });
}

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Comment> addComment(String postId, String content, {String? parentId}) async {
    final response = await _supabase.from('comments').insert({
      'post_id': postId,
      'author_id': _supabase.auth.currentUser!.id,
      'content': content,
      'parent_id': parentId,
    }).select().single();

    return Comment.fromJson(response);
  }

  Future<List<CommentWithAuthor>> getCommentsWithAuthor(String postId) async {
    final response = await _supabase
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');

    List<Comment> comments = (response as List).map((comment) => Comment.fromJson(comment)).toList();
    return _organizeCommentsWithAuthor(comments);
  }

  Future<List<CommentWithAuthor>> _organizeCommentsWithAuthor(List<Comment> flatComments) async {
    Map<String, CommentWithAuthor> commentMap = {};
    List<CommentWithAuthor> rootComments = [];

    for (var comment in flatComments) {
      var authorInfo = await _getAuthorInfo(comment.authorId);
      var commentWithAuthor = CommentWithAuthor(
        comment: comment,
        authorName: authorInfo['display_name'] ?? 'Unknown User',
        authorAvatarUrl: authorInfo['avatar_url'],
      );

      commentMap[comment.id] = commentWithAuthor;
      if (comment.parentId == null) {
        rootComments.add(commentWithAuthor);
      } else {
        commentMap[comment.parentId]?.comment.replies.add(comment);
      }
    }

    return rootComments;
  }

  Future<Map<String, dynamic>> _getAuthorInfo(String authorId) async {
    final response = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', authorId)
        .single();
    return response;
  }

  Stream<List<CommentWithAuthor>> subscribeToCommentsWithAuthor(String postId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap((events) async {
      List<Comment> comments = events.map((event) => Comment.fromJson(event)).toList();
      return await _organizeCommentsWithAuthor(comments);
    });
  }
}