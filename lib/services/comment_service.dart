import 'package:supabase_flutter/supabase_flutter.dart';

class Comment {
  final int id;
  final int postId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final int? parentId;
  List<Comment> replies;
  final bool isDeleted;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.replies = const [], 
    this.isDeleted = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      authorId: json['author_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      parentId: json['parent_id'],
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

class CommentWithAuthor {
  final Comment comment;
  final String authorName;
  final String? authorAvatarUrl;
  final List<CommentWithAuthor> replies;

  CommentWithAuthor({
    required this.comment,
    required this.authorName,
    this.authorAvatarUrl,
    List<CommentWithAuthor>? replies,
  }) : replies = replies ?? [];
}

class CommentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Comment> addComment(int postId, String content, {int? parentId}) async {
    final response = await _supabase.from('comments').insert({
      'post_id': postId,
      'author_id': _supabase.auth.currentUser!.id,
      'content': content,
      'parent_id': parentId,
    }).select().single();

    return Comment.fromJson(response);
  }

  Future<List<CommentWithAuthor>> getCommentsWithAuthor(int postId) async {
    final response = await _supabase
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');

    List<Comment> comments = (response as List).map((comment) => Comment.fromJson(comment)).toList();
    return _organizeCommentsWithAuthor(comments);
  }

  Future<List<CommentWithAuthor>> _organizeCommentsWithAuthor(List<Comment> flatComments) async {
    Map<int, CommentWithAuthor> commentMap = {};
    List<CommentWithAuthor> rootComments = [];

    // 첫 번째 패스: 모든 댓글을 맵에 추가
    for (var comment in flatComments) {
      var authorInfo = await _getAuthorInfo(comment.authorId);
      var commentWithAuthor = CommentWithAuthor(
        comment: comment,
        authorName: authorInfo['display_name'] ?? 'Unknown User',
        authorAvatarUrl: authorInfo['avatar_url'],
        replies: [],
      );

      commentMap[comment.id] = commentWithAuthor;
    }

    // 두 번째 패스: 부모-자식 관계 설정 및 루트 댓글 식별
    for (var comment in flatComments) {
      if (comment.parentId == null) {
        rootComments.add(commentMap[comment.id]!);
      } else {
        var parentComment = commentMap[comment.parentId];
        if (parentComment != null) {
          parentComment.replies.add(commentMap[comment.id]!);
        } else {
          print('Warning: Parent comment not found for comment ${comment.id}');
          rootComments.add(commentMap[comment.id]!);
        }
      }
    }

    return rootComments;
  }

  Future<Map<String, dynamic>> _getAuthorInfo(String authorId) async {
    final response = await _supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('user_id', authorId)
        .single();
    return response;
  }

  Stream<List<CommentWithAuthor>> subscribeToCommentsWithAuthor(int postId) {
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

  Future<void> deleteComment(int commentId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User must be logged in to delete a comment');

    // 1. 해당 댓글의 자식 댓글 수 확인
    final childComments = await Supabase.instance.client
        .from('comments')
        .select('id')
        .eq('parent_id', commentId);

    if (childComments.length == 0) {
      // 자식 댓글이 없는 경우: 완전히 삭제
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('author_id', user.id);
    } else {
      // 자식 댓글이 있는 경우: 소프트 삭제
      await Supabase.instance.client
          .from('comments')
          .update({'is_deleted': true})
          .eq('id', commentId)
          .eq('author_id', user.id);
    }
  }

  Future<void> softDeleteComment(int commentId) async {
    try {
      await _supabase
          .from('comments')
          .update({
            'is_deleted': true,
            'content': '[삭제된 댓글입니다]'
          })
          .eq('id', commentId);
    } catch (e) {
      print('Error soft deleting comment: $e');
      throw e;
    }
  }

  Future<void> updateComment(int commentId, String newContent) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User must be logged in to update a comment');

    await Supabase.instance.client
        .from('comments')
        .update({'content': newContent})
        .eq('id', commentId)
        .eq('author_id', user.id);
  }
}