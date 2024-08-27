import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplis_demo/widgets/user_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_screen.dart';
import 'write_post_screen.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;

  const HomeScreen({super.key, required this.isLoggedIn});

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
        final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', post['user_id'])
          .maybeSingle();
        post['author'] = profileResponse?['display_name'] ?? post['author'];
        post['avatar_url'] = profileResponse?['avatar_url'];
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
        'content': 'Check out this amazing content! #MZVibes #Trending. This is a longer content to demonstrate the truncation feature in the home screen.',
        'author': 'Influencer$index',
        'likes': index * 100,
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
    ).then((_) => _onRefresh());
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
              ? const Center(child: CircularProgressIndicator())
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
                          post: post,
                          isLoggedIn: widget.isLoggedIn,
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
                              UserAvatar(avatarUrl: post['avatar_url'], name: post['author'], radius: 20,),
                              const SizedBox(width: 10),
                              Text(
                                post['author'],
                                style: GoogleFonts.pacifico(
                                  textStyle: TextStyle(
                                    fontFamilyFallback: const ['eastSeaDokdo'],
                                    fontSize: 18,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ExpandableText(
                            text: post['content'],
                            maxLines: 2,
                            expandText: '더 보기',
                            collapseText: '접기',
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, color: Colors.purple.shade400),
                                  const SizedBox(width: 5),
                                  Text('${post['likes'] ?? 0}'),
                                ],
                              ),
                              const Icon(Icons.share, color: Colors.grey),
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
        onPressed: _navigateToWritePost,
        backgroundColor: Colors.purple.shade500,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final String expandText;
  final String collapseText;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.expandText = '더 보기',
    this.collapseText = '접기',
  });

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          secondChild: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Text(
            _expanded ? widget.collapseText : widget.expandText,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}