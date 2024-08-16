import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:maplis_demo/services/comment_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLoggedIn;

  const DetailScreen({
    Key? key,
    required this.post,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isLiked = false;
  int likeCount = 0;
  List<Comment> comments = [];
  TextEditingController commentController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  final CommentService _commentService = CommentService();
  late Stream<List<CommentWithAuthor>> _commentStream;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes'] ?? 0;
    isLiked = widget.post['isLiked'] ?? false;
    _commentStream = _commentService.subscribeToCommentsWithAuthor(widget.post['id']);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  String getAvatarUrl(String author) {
    final List<String> _backgroundColors = [
      '1E90FF',  // 도지블루
      '32CD32',  // 라임그린
      'FF4500',  // 오렌지레드
      '9932CC',  // 다크오키드
      '008080',  // 틸
      '8B4513',  // 새들브라운
      '4169E1',  // 로얄블루
      '800080',  // 퍼플
      '2F4F4F',  // 다크슬레이트그레이
      'DC143C',  // 크림슨
    ];

    final random = Random();
    final colorIndex = random.nextInt(_backgroundColors.length);
    final backgroundColor = _backgroundColors[colorIndex];

    return 'https://api.dicebear.com/6.x/initials/png?seed=$author&backgroundColor=$backgroundColor';
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
                        margin: EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.post['title'],
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black),
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
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.isLoggedIn && widget.post['avatar_url'] != null
                ? NetworkImage(widget.post['avatar_url'])
                : NetworkImage(getAvatarUrl(widget.post['author'])),
            radius: 24,
          ),
          SizedBox(width: 12),
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
            child: Text('팔로우', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: EdgeInsets.all(16),
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
                fontFamilyFallback: ['Noto Sans KR'],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (widget.post['image_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                widget.post['image_url'],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
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
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          SizedBox(height: 16),
          Text(
            widget.post['content'],
            style: GoogleFonts.notoSans(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistentInteractionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInteractionButton(
            icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: '좋아요 $likeCount',
            color: isLiked ? Colors.purpleAccent : Colors.grey,
            onPressed: () {
              setState(() {
                isLiked = !isLiked;
                likeCount += isLiked ? 1 : -1;
              });
            },
          ),
          _buildInteractionButton(
            icon: Icons.chat_bubble_outline,
            label: '댓글 ${comments.length}',
            color: Colors.grey,
            onPressed: () {
              // 댓글 섹션으로 스크롤
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          _buildInteractionButton(
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
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '댓글',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          SizedBox(height: 16),
          StreamBuilder<List<CommentWithAuthor>>(
            stream: _commentStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No comments yet.');
              } else {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(snapshot.data![index], 0);
                  },

                );
              }
            },
          ),
          SizedBox(height: 16),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentWithAuthor commentWithAuthor, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: commentWithAuthor.authorAvatarUrl != null
                    ? NetworkImage(commentWithAuthor.authorAvatarUrl!)
                    : NetworkImage(getAvatarUrl(commentWithAuthor.authorName)),
                radius: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(commentWithAuthor.authorName, style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Text(
                          getSmartTimeString(commentWithAuthor.comment.createdAt.toIso8601String()),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(commentWithAuthor.comment.content),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showReplyInput(commentWithAuthor.comment),
                      child: Text(
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
        if (commentWithAuthor.comment.replies.isNotEmpty)
          ...commentWithAuthor.comment.replies.map((reply) => _buildCommentItem(
              CommentWithAuthor(
                comment: reply,
                authorName: 'Unknown', // 여기서는 임시로 'Unknown'을 사용합니다. 실제로는 reply의 작성자 정보를 가져와야 합니다.
                authorAvatarUrl: null,
              ),
              depth + 1
          )),
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
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
        SizedBox(width: 8),
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
      } catch (e) {
        print('댓글 추가에 실패했습니다: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 추가에 실패했습니다.')),
        );
      }
    }
  }

  void _showReplyInput(Comment parentComment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '답글을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) async {
                      if (value.isNotEmpty) {
                        try {
                          await _commentService.addComment(
                            widget.post['id'],
                            value,
                            parentId: parentComment.id,
                          );
                          Navigator.pop(context);
                          // 댓글이 추가되면 스트림이 자동으로 업데이트되므로 _loadComments()를 호출할 필요가 없습니다.
                        } catch (e) {
                          print('답글 추가에 실패했습니다: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('답글 추가에 실패했습니다.')),
                          );
                        }
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // 답글 제출 로직
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
}