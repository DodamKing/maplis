import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import 'signup_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/exit_confirmation_mixin.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
    _setupBackButtonHandler();
    // _checkAutoLogin();
  }

  void _setupBackButtonHandler() {
    const platform = MethodChannel('com.example.maplis_demo/backButton');
    platform.setMethodCallHandler((call) async {
      if (call.method == "onBackPressed") {
        final shouldExit = await handlePopInvoked(false);
        if (shouldExit) {
          await platform.invokeMethod('handleBackPress');
        }
      }
    });
  }

  Future<void> _checkAutoLogin() async {
    setState(() => _isLoading = true);
    try {
      bool success = await _authService.autoLogin();
      if (success) {
        _navigateToMainScreen(isLoggedIn: true);
      } else {
        // 자동 로그인 실패 시 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('자동 로그인에 실패했습니다. 다시 로그인해 주세요.')),
        );
      }
    } catch (e) {
      print('자동 로그인 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중 오류가 발생했습니다. 다시 시도해 주세요.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      // bool success = await _authService.signIn(_emailController.text, _passwordController.text);
      bool success = await _authService.signInWithEmailAndPassword(_emailController.text, _passwordController.text);
      if (success) {
        // await _authService.setupBiometrics(context);
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
        final supabaseProvider = OAuthProvider.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == provider.toLowerCase(),
          orElse: () => throw Exception('Unsupported provider: $provider'),
        );

        await Supabase.instance.client.auth.signInWithOAuth(supabaseProvider);
      }
      // 소셜 로그인 성공 후 처리는 Supabase 인증 상태 변경 리스너에서 처리됩니다.
    } catch (e) {
      print('Social Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Social login failed. Please try again.')),
      );
    }
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
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                              child: const FaIcon(FontAwesomeIcons.google,
                                  color: Color(0xFF4285F4)),
                              onPressed: () => _socialLogin('google'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEE500), // 카카오 노란색
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/kakao_login_icon.svg',
                                width: 28,
                                height: 28,
                              ),
                              onPressed: () => _socialLogin('kakao'),
                            ),
                            const SizedBox(width: 16), // 간격 추가
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(8),
                              ),
                              child: const FaIcon(FontAwesomeIcons.apple,
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
                          child: const Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
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
