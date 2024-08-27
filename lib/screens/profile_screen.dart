import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplis_demo/widgets/user_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isLoggedIn;
  const ProfileScreen({super.key, required this.isLoggedIn});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

extension UserExtension on User {
  static final Map<String, dynamic> _extraData = {};

  void setExtraData(Map<String, dynamic> data) {
    _extraData[id] = data;
  }

  dynamic getExtraData(String key) {
    return _extraData[id]?[key];
  }

  String? get displayName => getExtraData('display_name');
  String? get avatarUrl => getExtraData('avatar_url');
// 필요한 추가 getter들...
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<User?> _loadUserData() async {
    if (widget.isLoggedIn) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('display_name, avatar_url')
            .eq('user_id', user.id)
            .single();

        user.setExtraData(response);
        return user;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<User?>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          return CustomScrollView(
            slivers: <Widget>[
              ProfileAppBar(isLoggedIn: widget.isLoggedIn, user: user, authService: _authService,),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    UserInfoSection(isLoggedIn: widget.isLoggedIn, user: user),
                    const SizedBox(height: 16),
                    const UserStatsSection(),
                    const SizedBox(height: 16),
                    const EditProfileButton(),
                    const SizedBox(height: 16),
                    const RecentActivitiesSection(),
                    const SizedBox(height: 16),
                    const UserPostsSection(),
                  ],
                ),
              ),
              if (!widget.isLoggedIn) const PrototypeModeIndicator(),
            ],
          );
        },
      ),
    );
  }
}

class ProfileAppBar extends StatelessWidget {
  final bool isLoggedIn;
  final User? user;
  final AuthService authService;

  const ProfileAppBar({super.key, required this.isLoggedIn, this.user, required this.authService});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('My Profile', style: GoogleFonts.pacifico(fontSize: 24)),
        background: ProfileBackground(isLoggedIn: isLoggedIn, user: user),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          onPressed: () => _showSettingsBottomSheet(context),
        ),
      ],
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text('Edit Profile', style: GoogleFonts.poppins()),
                onTap: () {
                  // Handle edit profile
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.green),
                title: Text('Privacy Settings', style: GoogleFonts.poppins()),
                onTap: () {
                  // Handle privacy settings
                  Navigator.pop(context);
                },
              ),
              if (isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: GoogleFonts.poppins()),
                  onTap: () async {
                    // await Supabase.instance.client.auth.signOut();
                    await authService.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                ),
              if (!isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                  title: Text('Exit Prototype', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
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
}

class ProfileBackground extends StatelessWidget {
  final bool isLoggedIn;
  final User? user;

  const ProfileBackground({super.key, required this.isLoggedIn, this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class UserInfoSection extends StatelessWidget {
  final bool isLoggedIn;
  final User? user;

  const UserInfoSection({super.key, required this.isLoggedIn, this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(avatarUrl: user?.avatarUrl, name: user?.displayName ?? user?.email?.split('@')[0] ?? 'User', radius: 50,),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    user?.displayName ?? 'CoolUser123',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                Text(
                    user?.userMetadata?['bio'] ?? 'Living my best life 🌟',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserStatsSection extends StatelessWidget {
  const UserStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn('Posts', '123'),
        _buildStatColumn('Followers', '10.5K'),
        _buildStatColumn('Following', '456'),
      ],
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
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.shade400,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 16)),
    );
  }
}

class RecentActivitiesSection extends StatelessWidget {
  const RecentActivitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Recent Activities',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
          ),
        ),
        _buildActivityItem(Icons.photo, 'Posted a new photo', '2 hours ago'),
        _buildActivityItem(Icons.favorite, 'Liked a post', 'Yesterday'),
        _buildActivityItem(Icons.comment, 'Commented on a post', '2 days ago'),
      ],
    );
  }

  Widget _buildActivityItem(IconData icon, String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple.shade400),
          const SizedBox(width: 12),
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

class UserPostsSection extends StatelessWidget {
  const UserPostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Your Posts',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}

class PrototypeModeIndicator extends StatelessWidget {
  const PrototypeModeIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.orange.withOpacity(0.1),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
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
    );
  }
}