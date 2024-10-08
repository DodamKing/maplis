import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../main.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String _statusMessage = '인증 확인 중...';
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _attemptAutoLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoLogin() async {
    try {
      setState(() => _statusMessage = '로그인 정보 확인 중...');
      bool success = await _authService.autoLogin();
      if (success) {
        setState(() => _statusMessage = '로그인 성공!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen(isLoggedIn: true)),
        );
      } else {
        setState(() => _statusMessage = '수동 로그인이 필요합니다.');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Auto login error: $e');
      setState(() => _statusMessage = '오류가 발생했습니다. 다시 시도해 주세요.');
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _showBiometricSetupDialog(String userId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('생체 인증 설정'),
          content: Text('로그인을 더 빠르고 안전하게 할 수 있도록 생체 인증을 설정하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('나중에'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen(isLoggedIn: true)),
                );
              },
            ),
            ElevatedButton(
              child: Text('설정하기'),
              onPressed: () async {
                Navigator.of(context).pop();
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainScreen(isLoggedIn: true)),
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade300, Colors.blue.shade200],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '너플리스',
                style: GoogleFonts.eastSeaDokdo(
                  fontSize: 72,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(5.0, 5.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: Colors.purple.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}