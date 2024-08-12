import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isLoggedIn;
  const ProfileScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Profile', style: GoogleFonts.poppins()),
                onTap: () {
                  // Handle edit profile
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.security, color: Colors.green),
                title: Text('Privacy Settings', style: GoogleFonts.poppins()),
                onTap: () {
                  // Handle privacy settings
                  Navigator.pop(context);
                },
              ),
              if (isLoggedIn)
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: GoogleFonts.poppins()),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                    );
                  },
                ),
              if (!isLoggedIn)
                ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.orange),
                  title: Text('Exit Prototype', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('My Profile', style: GoogleFonts.pacifico(fontSize: 24)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      'https://picsum.photos/seed/profile_background/800/600',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () => _showSettingsBottomSheet(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage('https://picsum.photos/seed/user/200'),
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CoolUser123',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)
                            ),
                            Text('Living my best life 🌟',
                                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Posts', '123'),
                      _buildStatColumn('Followers', '10.5K'),
                      _buildStatColumn('Following', '456'),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    child: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 16)),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Activities',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 16),
                  _buildActivityItem(Icons.photo, 'Posted a new photo', '2 hours ago'),
                  _buildActivityItem(Icons.favorite, 'Liked a post', 'Yesterday'),
                  _buildActivityItem(Icons.comment, 'Commented on a post', '2 days ago'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Posts',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      return Image.network(
                        'https://picsum.photos/seed/post$index/200',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (!isLoggedIn)
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.orange.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Prototype Mode',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)
        ),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])
        ),
      ],
    );
  }

  Widget _buildActivityItem(IconData icon, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.shade400),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: GoogleFonts.poppins(fontSize: 16)),
                Text(time, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}