import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);
    if (response.user != null) {
      await _secureStorage.write(key: 'lastSignedInUser', value: response.user!.id);
      return true;
    }
    return false;
  }

  Future<bool> setBiometricAuth(String userId) async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    if (!canCheckBiometrics) {
      print("이 기기에서는 생체 인증을 사용할 수 없습니다.");
      return false;
    }

    bool didAuthenticate = await _authenticateWithBiometrics('생체 인증을 설정하려면 인증해주세요.');
    if (didAuthenticate) {
      await _secureStorage.write(key: 'biometric_enabled_$userId', value: 'true');
      return true;
    }
    return false;
  }

  Future<bool> isBiometricEnabled(String userId) async {
    String? enabled = await _secureStorage.read(key: 'biometric_enabled_$userId');
    return enabled == 'true';
  }

  String getCurrentUserId() {
    final user = supabase.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    throw Exception('No user is currently logged in');
  }

  Future<bool> autoLogin() async {
    try {
      print("자동 로그인 시도");
      final session = supabase.auth.currentSession;

      if (session != null) {
        print("유효한 세션 발견. 사용자: ${session.user.email}");

        String? storedUserId = await _secureStorage.read(key: 'lastSignedInUser');
        if (storedUserId != session.user.id) {
          print("저장된 사용자 ID와 현재 세션의 사용자 ID가 일치하지 않습니다.");
          return false;
        }

        bool biometricEnabled = await isBiometricEnabled(session.user.id);
        if (!biometricEnabled) {
          print("이 계정에 대해 생체 인증이 설정되지 않았습니다.");
          return false;
        }

        bool authenticated = await _authenticateWithBiometrics('로그인하려면 생체 인증을 사용하세요.');
        if (authenticated) {
          print("생체 인증 성공. 자동 로그인 완료.");
          return true;
        } else {
          print("생체 인증 실패.");
          return false;
        }
      } else {
        print("유효한 세션이 없습니다.");
        return false;
      }
    } catch (e) {
      print('자동 로그인 중 예상치 못한 오류 발생: $e');
      return false;
    }
  }

  Future<bool> _authenticateWithBiometrics(String reason) async {
    try {
      List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      print("사용 가능한 생체 인증 방식: $availableBiometrics");

      String getBiometricHint(List<BiometricType> types) {
        if (types.contains(BiometricType.face)) {
          return '얼굴을 카메라에 비춰주세요';
        } else if (types.contains(BiometricType.fingerprint)) {
          return '지문 센서에 손가락을 대주세요';
        } else if (types.contains(BiometricType.iris)) {
          return '홍채를 카메라에 비춰주세요';
        } else {
          return '생체 인증을 시작합니다';
        }
      }

      String biometricHint = getBiometricHint(availableBiometrics);

      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: '생체 인증',
            cancelButton: '취소',
            biometricHint: biometricHint,
            biometricNotRecognized: '인식할 수 없습니다',
            biometricSuccess: '인증 성공',
            biometricRequiredTitle: '생체 인증이 필요합니다',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true,
          useErrorDialogs: false,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print("생체 인증 중 오류 발생: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    final userId = supabase.auth.currentUser?.id;
    await supabase.auth.signOut();
    if (userId != null) {
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
    }
    await _secureStorage.delete(key: 'lastSignedInUser');
  }
}