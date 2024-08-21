import 'package:flutter/services.dart';
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
      rethrow;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!await canCheckBiometrics()) {
      print('이 기기에서는 생체 인증을 사용할 수 없습니다.');
      return false;
    }

    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!canCheckBiometrics || availableBiometrics.isEmpty) {
        throw Exception('Biometric authentication is not available on this device');
      }

      return await _localAuth.authenticate(
        localizedReason: '지문을 인식하여 로그인해주세요',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        throw Exception('Biometric authentication is not available on this device');
      } else if (e.code == 'NotEnrolled') {
        throw Exception('No biometric credentials are enrolled on this device');
      } else {
        throw Exception('Biometric authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Biometric authentication error: $e');
    }
  }

  Future<bool> autoLogin() async {
    try {
      String? token = await _storage.read(key: 'auth_token');
      if (token == null) {
        print('저장된 토큰이 없습니다.');
        return false;
      }

      // 세션 복구 시도
      try {
        final response = await supabase.auth.recoverSession(token);
        if (response.user == null) {
          print('세션 복구 실패: 유효하지 않은 토큰');
          await _storage.delete(key: 'auth_token');
          return false;
        }
      } catch (e) {
        print('세션 복구 오류: $e');
        await _storage.delete(key: 'auth_token');
        return false;
      }

      // 생체 인증 가능 여부 확인
      bool canUseBiometrics = await canCheckBiometrics();
      if (!canUseBiometrics) {
        print('생체 인증을 사용할 수 없습니다. 토큰만으로 로그인 진행.');
        return true; // 생체 인증 없이 토큰만으로 로그인 성공
      }

      // 생체 인증 시도
      bool authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        print('생체 인증 실패');
        return false;
      }

      print('자동 로그인 성공');
      return true;
    } catch (e) {
      print('자동 로그인 중 예상치 못한 오류 발생: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    await _storage.delete(key: 'auth_token');
  }

  Future<bool> isTokenStored() async {
    String? token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> isSessionValid() async {
    try {
      final session = supabase.auth.currentSession;
      // return session != null && DateTime.now().isBefore(session.expiresAt ?? DateTime.now());
      return session != null;
    } catch (e) {
      print('세션 확인 오류: $e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      print('생체 인증 지원 확인 오류: $e');
      return false;
    }
  }

  Future<bool> attemptAutoLogin() async {
    if (await isTokenStored() && await isSessionValid()) {
      if (await canCheckBiometrics()) {
        return await authenticateWithBiometrics();
      }
      return true;  // 생체 인증을 지원하지 않는 경우 바로 로그인 성공
    }
    return false;
  }
}