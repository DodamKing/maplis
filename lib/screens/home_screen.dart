import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_screen.dart';
import 'write_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maplis', style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white)),
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
        child: ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        title: 'Trending Topic #$index',
                        author: 'Influencer$index',
                        content: 'Check out this amazing content! #MZVibes #Trending',
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
                              backgroundImage: NetworkImage('https://picsum.photos/seed/Influencer$index/100'),
                              radius: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Influencer$index',
                              style: GoogleFonts.pacifico(
                                textStyle: TextStyle(
                                  fontSize: 18,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Trending Topic #$index',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Check out this amazing content! #MZVibes #Trending',
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
                                Text('${index * 100}'),
                                SizedBox(width: 15),
                                Icon(Icons.thumb_down, color: Colors.blue.shade400),
                                SizedBox(width: 5),
                                Text('${index * 10}'),
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WritePostScreen()),
          );
        },
        backgroundColor: Colors.purple.shade500,
      ),
    );
  }
}