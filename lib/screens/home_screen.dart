import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_screen.dart';
import 'write_post_screen.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;

  const HomeScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _fetchPosts();
      _subscribeToChanges();
    } else {
      _loadPrototypePosts();
    }
  }

  void _subscribeToChanges() {
    Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
      _fetchPosts();
    });
  }

  Future<void> _fetchPosts() async {
    try {
      final postsResponse = await Supabase.instance.client
          .from('posts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(20);

      List<Map<String, dynamic>> posts = List<Map<String, dynamic>>.from(postsResponse);

      for (var post in posts) {
        post['author'] = (post['author'] as String?) ?? 'test';
      }

      setState(() {
        _posts = posts;
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching posts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _loadPrototypePosts() {
    setState(() {
      _posts = List.generate(20, (index) => {
        'id': index,
        'title': 'Trending Topic #$index',
        'content': 'Check out this amazing content! #MZVibes #Trending',
        'author': 'Influencer$index',
        'likes': index * 100,
        'dislikes': index * 10,
      });
      _isLoading = false;
    });
  }

  void _onRefresh() async {
    if (widget.isLoggedIn) {
      await _fetchPosts();
    } else {
      _loadPrototypePosts();
    }
    _refreshController.refreshCompleted();
  }

  void _navigateToWritePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WritePostScreen(
          isLoggedIn: widget.isLoggedIn,
          onPrototypePostSaved: (post) {
            setState(() {
              _posts.insert(0, post);
            });
          },
        ),
      ),
    ).then((_) => _onRefresh()); // 글 작성 후 새로고침
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('너플리스', style: GoogleFonts.eastSeaDokdo(fontSize: 40, color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_rounded, color: Colors.white), onPressed: () {}),
        ],
        backgroundColor: Colors.purple.shade400,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          title: post['title'],
                          author: post['author'],
                          content: post['content'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: widget.isLoggedIn
                                ? (post['avatar_url'] != null
                                    ? NetworkImage(post['avatar_url'])
                                    : NetworkImage('https://ui-avatars.com/api/?name=${post['author']}&background=random'))
                                : NetworkImage('https://picsum.photos/seed/${post['author']}/100'),
                                radius: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                post['author'],
                                style: GoogleFonts.pacifico(
                                  textStyle: TextStyle(
                                    fontFamilyFallback: ['eastSeaDokdo'],
                                    fontSize: 18,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            post['title'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            post['content'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, color: Colors.purple.shade400),
                                  SizedBox(width: 5),
                                  Text('${post['likes'] ?? 0}'),
                                  SizedBox(width: 15),
                                  Icon(Icons.thumb_down, color: Colors.blue.shade400),
                                  SizedBox(width: 5),
                                  Text('${post['dislikes'] ?? 0}'),
                                ],
                              ),
                              Icon(Icons.share, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: _navigateToWritePost,
        backgroundColor: Colors.purple.shade500,
      ),
    );
  }
}