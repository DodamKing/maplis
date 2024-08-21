import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _storage.write(key: 'auth_token', value: response.session?.accessToken);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

    if (!canCheckBiometrics) {
      return false;
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: '지문을 인식하여 로그인해주세요',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Biometric auth error: $e');
      return false;
    }
  }

  Future<bool> autoLogin() async {
    String? token = await _storage.read(key: 'auth_token');
    if (token != null) {
      bool authenticated = await authenticateWithBiometrics();
      if (authenticated) {
        try {
          final response = await supabase.auth.recoverSession(token);
          return response.user != null;
        } catch (e) {
          print('Auto login error: $e');
          await _storage.delete(key: 'auth_token');
        }
      }
    }
    return false;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _storage.delete(key: 'auth_token');
  }
}