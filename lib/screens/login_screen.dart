import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/exit_confirmation_mixin.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ExitConfirmationMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    bool success = await _authService.autoLogin();
    if (success) {
      _navigateToMainScreen(isLoggedIn: true);
    }
  }

  Future<void> _login() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        _navigateToMainScreen(isLoggedIn: true);
      } else
        throw Exception('Login failed');
    } catch (e) {
      print('Login Error: $e');
      String msg = 'Login error occurred. Please try again later.';
      if (e.toString().contains('400'))
        msg = 'Incorrect email or password. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _biometricLogin() async {
    bool success = await _authService.autoLogin();
    if (success) {
      _navigateToMainScreen(isLoggedIn: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric login failed. Please try again or use email/password.')),
      );
    }
  }

  Future<void> _socialLogin(String provider) async {
    // return print('$provider 구현이 필요합니다');
    try {
      if (provider == 'kakao') {
        print('카카오 로그인 따로?');
      } else {
        await Supabase.instance.client.auth.signInWithOAuth(
          Provider.values
              .firstWhere((e) => e.toString() == 'Provider.$provider'),
        );
      }
      // 소셜 로그인 성공 후 처리는 Supabase 인증 상태 변경 리스너에서 처리됩니다.
    } catch (e) {
      print('Social Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Social login failed. Please try again.')),
      );
    }
  }

  void _usePrototype() {
    _navigateToMainScreen(isLoggedIn: false);
  }

  void _navigateToMainScreen({required bool isLoggedIn}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => MainScreen(isLoggedIn: isLoggedIn)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.blue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome to ',
                              style: GoogleFonts.pacifico(
                                fontSize: 32,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '너플리스',
                              style: GoogleFonts.eastSeaDokdo(
                                fontSize: 46,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.purple.shade400,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                        // const SizedBox(height: 24),
                        // ElevatedButton.icon(
                        //   icon: Icon(Icons.fingerprint),
                        //   label: Text('Login with Biometrics'),
                        //   onPressed: _biometricLogin,
                        //   style: ElevatedButton.styleFrom(
                        //     foregroundColor: Colors.white,
                        //     backgroundColor: Colors.green.shade400,
                        //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(12),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(8),
                              ),
                              child: FaIcon(FontAwesomeIcons.google,
                                  color: Color(0xFF4285F4)),
                              onPressed: () => _socialLogin('google'),
                            ),
                            SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFEE500), // 카카오 노란색
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(8),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/kakao_login_icon.svg',
                                width: 28,
                                height: 28,
                              ),
                              onPressed: () => _socialLogin('kakao'),
                            ),
                            SizedBox(width: 16), // 간격 추가
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(8),
                              ),
                              child: FaIcon(FontAwesomeIcons.apple,
                                  color: Colors.white),
                              onPressed: () => _socialLogin('apple'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        // const SizedBox(height: 24),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     borderRadius: BorderRadius.circular(30),
                        //     gradient: LinearGradient(
                        //       colors: [Colors.purple.shade400, Colors.blue.shade400],
                        //       begin: Alignment.centerLeft,
                        //       end: Alignment.centerRight,
                        //     ),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.purple.withOpacity(0.5),
                        //         spreadRadius: 1,
                        //         blurRadius: 5,
                        //         offset: Offset(0, 3),
                        //       ),
                        //     ],
                        //   ),
                        //   child: ElevatedButton.icon(
                        //     icon: Icon(Icons.rocket_launch, color: Colors.white),
                        //     label: Text(
                        //       'Use Prototype',
                        //       style: GoogleFonts.poppins(
                        //         fontSize: 18,
                        //         fontWeight: FontWeight.bold,
                        //         color: Colors.white,
                        //       ),
                        //     ),
                        //     onPressed: _usePrototype,
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.transparent,
                        //       foregroundColor: Colors.white,
                        //       shadowColor: Colors.transparent,
                        //       padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
