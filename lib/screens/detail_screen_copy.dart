import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:maplis_demo/services/comment_service.dart';
import 'package:maplis_demo/widgets/user_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:maplis_demo/services/like_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLoggedIn;

  const DetailScreen({
    super.key,
    required this.post,
    required this.isLoggedIn,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isLiked = false;
  int likeCount = 0;
  TextEditingController commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CommentService _commentService = CommentService();
  late Stream<List<CommentWithAuthor>> _commentStream;

  final SupabaseLikeService _likeService = SupabaseLikeService();
  late Stream<bool> _isLikedStream;
  late Stream<int> _likeCountStream;

  @override
  void initState() {
    super.initState();

    _commentStream =
        _commentService.subscribeToCommentsWithAuthor(widget.post['id']);

    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _isLikedStream =
        _likeService.isLikedByUser(widget.post['id'], currentUserId);
    _likeCountStream = _likeService.getLikeCount(widget.post['id']);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    commentController.dispose();
    super.dispose();
  }

  String getSmartTimeString(String? dateString) {
    if (dateString == null) return '날짜 정보 없음';

    DateTime postDate = DateTime.parse(dateString);
    DateTime now = DateTime.now();
    Duration difference = now.difference(postDate);

    if (difference.inDays > 7) {
      return DateFormat('yy.MM.dd').format(postDate);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  int _calculateTotalCommentCount(List<CommentWithAuthor> comments) {
    int count = 0;
    for (var comment in comments) {
      count++; // 부모 댓글 카운트
      count += _countReplies(comment.replies); // 답글 카운트
    }
    return count;
  }

  int _countReplies(List<CommentWithAuthor> replies) {
    int count = replies.length;
    for (var reply in replies) {
      count += _countReplies(reply.replies);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildPersistentAppBar(),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          children: [
                            _buildPostHeader(),
                            _buildPostContent(),
                            _buildCommentSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPersistentInteractionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersistentAppBar() {
    return Container(
      color: Colors.white.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.post['title'],
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {
              // 추가 옵션 메뉴
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: widget.post['avatar_url'],
            name: widget.post['author'],
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post['author'],
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  getSmartTimeString(widget.post['created_at']),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // 팔로우 기능
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('팔로우',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.post['title'],
              style: GoogleFonts.notoSans(
                textStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                  fontFamilyFallback: const ['Noto Sans KR'],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.post['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  widget.post['image_url'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      width: double.infinity,
                      height: 200, // 적절한 높이 설정
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.post['content'],
              style: GoogleFonts.notoSans(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersistentInteractionBar() {
    return StreamBuilder<List<CommentWithAuthor>>(
      stream: _commentStream,
      builder: (context, commentSnapshot) {
        int totalCommentCount = commentSnapshot.hasData
            ? _calculateTotalCommentCount(commentSnapshot.data!)
            : 0;

        return StreamBuilder<bool>(
          stream: _isLikedStream,
          builder: (context, isLikedSnapshot) {
            return StreamBuilder<int>(
              stream: _likeCountStream,
              builder: (context, likeCountSnapshot) {
                bool isLiked = isLikedSnapshot.data ?? false;
                int likeCount = likeCountSnapshot.data ?? 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                    Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInteractionButton(
                        key: ValueKey('like_button_$isLiked'),
                        icon:
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        label: '좋아요 $likeCount',
                        color: isLiked ? Colors.purpleAccent : Colors.grey,
                        onPressed: () {
                          final currentUserId =
                              Supabase.instance.client.auth.currentUser!.id;
                          final postId = widget.post['id'] as int;
                          _likeService.toggleLike(postId, currentUserId);
                        },
                      ),
                      _buildInteractionButton(
                        key: ValueKey('comment_button_$totalCommentCount'),
                        icon: Icons.chat_bubble_outline,
                        label: '댓글 $totalCommentCount',
                        color: Colors.grey,
                        onPressed: () {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                      _buildInteractionButton(
                        key: const ValueKey('save_button'),
                        icon: Icons.bookmark_border,
                        label: '저장',
                        color: Colors.grey,
                        onPressed: () {
                          // 저장 기능
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInteractionButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<CommentWithAuthor>>(
            stream: _commentStream,
            builder: (context, snapshot) {
              int totalCommentCount = 0;
              if (snapshot.hasData) {
                totalCommentCount = _calculateTotalCommentCount(snapshot.data!);
              }
              return Text(
                '댓글 ($totalCommentCount)',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<CommentWithAuthor>>(
            stream: _commentStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('아직 댓글이 없습니다.');
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(snapshot.data![index], 0);
                  },
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentWithAuthor commentWithAuthor, int depth) {
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;
    final isAuthor = commentWithAuthor.comment.authorId == currentUserId;
    final isDeleted = commentWithAuthor.comment.isDeleted ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDeleted)
                UserAvatar(
                  avatarUrl: commentWithAuthor.authorAvatarUrl,
                  name: commentWithAuthor.authorName,
                  radius: 16,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDeleted ? '삭제된 댓글' : commentWithAuthor.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDeleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        if (isAuthor && !isDeleted)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _showEditCommentDialog(commentWithAuthor),
                                color: Colors.blue,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () {
                                  showDeleteConfirmationDialog(
                                    context,
                                        () => _deleteComment(commentWithAuthor.comment.id),
                                  );
                                },
                                color: Colors.red,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commentWithAuthor.comment.content,
                      style: TextStyle(
                        color: isDeleted ? Colors.grey : Colors.black,
                        fontStyle:
                        isDeleted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getSmartTimeString(commentWithAuthor.comment.createdAt
                          .toIso8601String()),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (!isDeleted)
                      GestureDetector(
                        onTap: () => _showReplyInput(commentWithAuthor.comment),
                        child: const Text(
                          '답글 달기',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (commentWithAuthor.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Column(
              children: commentWithAuthor.replies.map((reply) {
                return _buildCommentItem(reply, depth + 1);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: '댓글을 입력하세요...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.send, color: Colors.purple.shade400),
          onPressed: _addComment,
        ),
      ],
    );
  }

  void _addComment() async {
    if (commentController.text.isNotEmpty) {
      try {
        await _commentService.addComment(
          widget.post['id'],
          commentController.text,
        );
        commentController.clear();
        // 댓글이 추가되면 스트림이 자동으로 업데이트되므로 _loadComments()를 호출할 필요가 없습니다.

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        setState(() {
          _commentStream =
              _commentService.subscribeToCommentsWithAuthor(widget.post['id']);
        });
      } catch (e) {
        print('댓글 추가에 실패했습니다: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 추가에 실패했습니다.')),
        );
      }
    }
  }

  void _showReplyInput(Comment parentComment) {
    final TextEditingController replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: replyController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '답글을 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: (value) {
                        _submitReply(value, parentComment.id);
                        Navigator.pop(context);
                      }),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _submitReply(replyController.text, parentComment.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitReply(String content, int parentId) async {
    if (content.isNotEmpty) {
      try {
        await _commentService.addComment(
          widget.post['id'],
          content,
          parentId: parentId,
        );

        setState(() {
          _commentStream =
              _commentService.subscribeToCommentsWithAuthor(widget.post['id']);
        });
      } catch (e) {
        print('답글 추가에 실패했습니다: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('답글 추가에 실패했습니다.')),
        );
      }
    }
  }

  void _deleteComment(int commentId) async {
    try {
      // await _commentService.softDeleteComment(commentId);
      await _commentService.deleteComment(commentId);
      // 댓글 삭제 후 댓글 목록 새로고침
      setState(() {
        _commentStream =
            _commentService.subscribeToCommentsWithAuthor(widget.post['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } catch (e) {
      print('댓글 삭제 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  void showDeleteConfirmationDialog(BuildContext context, Function onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade100, Colors.blue.shade100],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  '댓글을 삭제하시겠습니까?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '이 작업은 되돌릴 수 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCommentDialog(CommentWithAuthor commentWithAuthor) {
    final TextEditingController editController = TextEditingController(text: commentWithAuthor.comment.content);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade100, Colors.blue.shade100],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  '댓글 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    hintText: "수정할 내용을 입력하세요",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        _updateComment(commentWithAuthor.comment.id, editController.text);
                        Navigator.of(context).pop();
                      },
                      child: const Text('수정'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateComment(int commentId, String newContent) async {
    try {
      await _commentService.updateComment(commentId, newContent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 수정되었습니다.')),
      );
      // 댓글 목록 새로고침
      setState(() {
        _commentStream = _commentService.subscribeToCommentsWithAuthor(widget.post['id']);
      });
    } catch (e) {
      print('댓글 수정 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 수정 중 오류가 발생했습니다.')),
      );
    }
  }
}
