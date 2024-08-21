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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    setState(() => _isLoading = true);
    try {
      bool success = await _authService.autoLogin();
      if (success) {
        _navigateToMainScreen(isLoggedIn: true);
      }
    } catch (e) {
      print('자동 로그인 오류: $e');
      // 오류 발생 시 사용자에게 알림을 표시할 수 있습니다.
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      bool success = await _authService.signIn(_emailController.text, _passwordController.text);
      if (success) {
        _navigateToMainScreen(isLoggedIn: true);
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      print('Login Error: $e');

      String msg = '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';

      if (e is AuthException) {
        msg = '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
        if (e.toString().contains('400')) msg = '이메일 주소나 비밀번호가 올바르지 않아요. 다시 한 번 확인해 주세요.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _biometricLogin() async {
    try {
      bool success = await _authService.autoLogin();
      if (success) {
        _navigateToMainScreen(isLoggedIn: true);
      } else {
        throw Exception('Biometric login failed');
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('not available')) {
        errorMessage = '이 기기에서는 생체 인증을 사용할 수 없습니다.';
      } else if (e.toString().contains('not enrolled')) {
        errorMessage = '생체 인증이 설정되어 있지 않습니다. 기기 설정에서 생체 인증을 등록해주세요.';
      } else if (e.toString().contains('failed')) {
        errorMessage = '생체 인증에 실패했습니다. 다시 시도하거나 이메일/비밀번호로 로그인해주세요.';
      } else {
        errorMessage = '생체 인증 중 오류가 발생했습니다. 다시 시도해주세요.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
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
