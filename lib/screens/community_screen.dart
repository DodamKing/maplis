import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore',
            style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white)
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {}
          ),
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
          itemCount: 10,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white.withOpacity(0.9),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage('https://picsum.photos/seed/community$index/100'),
                  radius: 30,
                ),
                title: Text(
                    'Trending Topic #$index',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.purple.shade700
                    )
                ),
                subtitle: Text(
                    '${index * 1000 + 500} members',
                    style: GoogleFonts.poppins(
                        color: Colors.black54
                    )
                ),
                trailing: ElevatedButton(
                  child: Text('Join',
                      style: GoogleFonts.poppins(color: Colors.white)
                  ),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                onTap: () {
                  // Navigate to community page
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_rounded, color: Colors.white),
        onPressed: () {},
        backgroundColor: Colors.purple.shade500,
      ),
    );
  }
}