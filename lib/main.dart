import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplis_demo/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/exit_confirmation_mixin.dart';
import 'screens/authentication_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '너플리스',
      theme: ThemeData(
        primaryColor: Colors.purple.shade400,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple.shade400,
          secondary: Colors.blue.shade400,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.purple.shade400,
          titleTextStyle: GoogleFonts.pacifico(
            fontSize: 28,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardTheme(
          elevation: 5,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          color: Colors.white.withOpacity(0.9),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ),
      home: const AuthenticationWrapper(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isLoggedIn;

  const MainScreen({super.key, required this.isLoggedIn});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with ExitConfirmationMixin {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(isLoggedIn: widget.isLoggedIn),
      const CommunityScreen(),
      ProfileScreen(isLoggedIn: widget.isLoggedIn),
    ];
    if (widget.isLoggedIn) {
      _checkBiometricSetup();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkBiometricSetup() async {
    try {
      String userId = _authService.getCurrentUserId();
      bool biometricEnabled = await _authService.isBiometricEnabled(userId);
      if (!biometricEnabled && mounted) {
        // 화면이 완전히 빌드된 후 다이얼로그를 표시하기 위해 WidgetsBinding.instance.addPostFrameCallback 사용
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBiometricSetupDialog(userId);
        });
      }
    } catch (e) {
      print('Error checking biometric setup: $e');
    }
  }

  Future<void> _showBiometricSetupDialog(String userId) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('생체 인증 설정'),
          content: Text('로그인을 더 빠르고 안전하게 할 수 있도록 생체 인증을 설정하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('나중에'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('설정하기'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      bool success = await _authService.setBiometricAuth(userId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생체 인증이 설정되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('생체 인증 설정에 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: handlePopInvoked,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade300, Colors.blue.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: _screens[_selectedIndex],
              bottomNavigationBar: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_rounded), label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.explore_rounded), label: 'Explore'),
                  NavigationDestination(
                      icon: Icon(Icons.person_rounded), label: 'Profile'),
                ],
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.9),
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
              ),
            ),
          ),
        ));
  }
}
