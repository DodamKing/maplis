import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  File? _profileImage;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _nicknameError;

  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _nicknameController.addListener(_validateNickname);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _nicknameController.removeListener(_validateNickname);
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    setState(() {
      if (_emailController.text.isEmpty) {
        _emailError = null;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
        _emailError = 'Enter a valid email';
      } else {
        _emailError = null;
      }
    });
  }

  void _validateNickname() {
    setState(() {
      if (_nicknameController.text.isEmpty) {
        _nicknameError = null;
      } else if (_nicknameController.text.length < 3) {
        _nicknameError = 'Nickname must be at least 3 characters';
      } else {
        _nicknameError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      String password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = null;
        _passwordStrength = '';
      } else if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        _passwordStrength = 'Weak';
      } else if (!_isPasswordStrong) {
        _passwordError = 'Include uppercase, lowercase, number, and special character';
        _passwordStrength = 'Medium';
      } else {
        _passwordError = null;
        _passwordStrength = 'Strong';
      }
    });
  }

  bool get _isPasswordStrong {
    String password = _passwordController.text;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return password.length >= 8 && hasUppercase && hasDigits && hasLowercase && hasSpecialCharacters;
  }


  bool get _isFormValid {
    return _emailError == null && _emailController.text.isNotEmpty &&
        _passwordError == null && _passwordController.text.isNotEmpty &&
        _passwordStrength != 'Weak' &&
        _agreeToTerms;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      int fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large. Compressing...')),
        );
        file = await _compressImage(file);
      }
      setState(() {
        _profileImage = file;
      });
    }
  }

  Future<File> _compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
    final splitName = filePath.substring(0, (lastIndex));
    final outPath = "${splitName}_compressed.jpg";

    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
    );

    return File(compressedImage!.path);
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final String path = 'avatars/${DateTime.now().toIso8601String()}.$fileExt';
      final fileBytes = await imageFile.readAsBytes();
      await Supabase.instance.client.storage.from('publics').uploadBinary(path, fileBytes);
      return Supabase.instance.client.storage.from('publics').getPublicUrl(path);
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 중 오류가 발생했습니다.')),
      );
      return null;
    }
  }

  void _signUp() async {
    if (_formKey.currentState!.validate() && _isFormValid) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? avatarFileNm;
        if (_profileImage != null) {
          avatarFileNm = await _uploadImage(_profileImage!);
        }

        String nickname = _nicknameController.text.isNotEmpty
            ? _nicknameController.text
            : _emailController.text.split('@')[0];

        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          // data: {
          //   'display_name': nickname,
          //   'avatar_url': avatarFileNm,
          // },
        );

        if (response.user != null) {
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'user_id': response.user!.id,
              'display_name': nickname,
              'avatar_url': avatarFileNm,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('회원가입이 완료되었습니다!\n지금 바로 로그인하여 서비스를 이용해 보세요.')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } catch (profileError) {
            // If profile creation fails, delete the user
            await Supabase.instance.client.auth.admin.deleteUser(response.user!.id);
            print('Profile creation failed: $profileError');
            throw Exception('프로필 생성 중 오류가 발생했습니다.');
          }
        } else {
          throw Exception('회원가입에 실패했습니다.');
        }
      } on AuthException catch (e) {
        print('SignUp Error: $e');  // Log the detailed error
        if (e.statusCode == '422') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 등록된 이메일 주소입니다. 다른 이메일을 사용해 주세요.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.')),
          );
        }
      } catch (e) {
        print('SignUp Error: $e');  // Log the detailed error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create Account',
                      style: GoogleFonts.pacifico(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    if (_profileImage == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Profile image (optional)',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email),
                        errorText: _emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        errorText: _passwordError,
                        suffixIcon: _passwordStrength.isNotEmpty
                            ? Tooltip(
                          message: 'Password strength: $_passwordStrength',
                          child: Icon(
                            _passwordStrength == 'Weak' ? Icons.sentiment_very_dissatisfied
                                : _passwordStrength == 'Medium' ? Icons.sentiment_satisfied
                                : Icons.sentiment_very_satisfied,
                            color: _passwordStrength == 'Weak' ? Colors.red
                                : _passwordStrength == 'Medium' ? Colors.orange
                                : Colors.green,
                          ),
                        )
                            : null,
                      ),
                      obscureText: true,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                    if (_passwordStrength.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Password Strength: $_passwordStrength',
                          style: TextStyle(
                            color: _passwordStrength == 'Weak' ? Colors.red
                                : _passwordStrength == 'Medium' ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: 'Nickname (optional)',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person),
                        errorText: _nicknameError,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('I agree to the Terms and Conditions'),
                      value: _agreeToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreeToTerms = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      tileColor: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isFormValid && !_isLoading ? _signUp : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: _isFormValid ? Colors.purple.shade400 : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign Up'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Already have an account? Login',
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
    );
  }
}