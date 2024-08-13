import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class WritePostScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Function(Map<String, dynamic>) onPrototypePostSaved;

  const WritePostScreen({
    Key? key,
    required this.isLoggedIn,
    required this.onPrototypePostSaved
  }) : super(key: key);

  @override
  _WritePostScreenState createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _savePost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isLoggedIn) {
        await _saveToSupabase();
      } else {
        _saveToPrototype();
      }
      Navigator.pop(context);
    } catch (e) {
      print('에러 여기서 나는 거지? $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving post: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToSupabase() async {
    String? imageUrl;
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      final fileExt = _image!.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      await Supabase.instance.client.storage
          .from('post_images')
          .uploadBinary(fileName, bytes);
      imageUrl = Supabase.instance.client.storage
          .from('post_images')
          .getPublicUrl(fileName);
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      final postData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'user_id': user.id,
      };

      if (imageUrl != null) {
        postData['image_url'] = imageUrl;
      }

      await Supabase.instance.client.from('posts').insert(postData);
    } catch (e) {
      print('Error saving post: $e');
      rethrow;
    }
  }

  void _saveToPrototype() {
    final post = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': _titleController.text,
      'content': _contentController.text,
      'image_path': _image?.path,
      'author': 'Prototype User',
      'created_at': DateTime.now().toIso8601String(),
      'likes': 0,
      'dislikes': 0,
    };
    widget.onPrototypePostSaved(post);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: 'Title',
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                hintText: 'What\'s on your mind?',
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.poppins(fontSize: 16),
                              maxLines: null,
                              minLines: 5,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_image != null) ...[
                          Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(_image!),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _removeImage,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: getImage,
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        label: Text('Add Photo', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.purple.shade400,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePost,
                      child: Text('Post', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}