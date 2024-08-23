import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth_android/local_auth_android.dart';
// import 'package:local_auth_ios/local_auth_ios.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);
    if (response.user != null) {
      return true;
    }
    return false;
  }

  // Future<bool> showBiometricSetupDialog(BuildContext context) async {
  //   return await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('생체 인증 설정'),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text('로그인을 더 빠르고 안전하게 할 수 있도록 생체 인증을 설정하시겠습니까?'),
  //               SizedBox(height: 10),
  //               Text('이 기능을 사용하면 다음 로그인부터 지문이나 얼굴 인식으로 빠르게 로그인할 수 있습니다.'),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text('나중에'),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //           ElevatedButton(
  //             child: Text('설정하기'),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   ) ?? false;
  // }

  Future<bool> autoLogin() async {
    try {
      print("자동 로그인 시도");
      final session = supabase.auth.currentSession;

      if (session != null) {
        print("유효한 세션 발견. 사용자: ${session.user.email}");

        // 세션 만료 확인
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now < session.expiresAt!) {
          print("세션이 유효합니다. 지문 인식 시도.");

          // 지문 인식 가능 여부 확인
          bool authenticated = await _authenticateWithBiometrics();
          if (authenticated) {
            print("지문 인식 성공. 자동 로그인 완료.");
            return true;
          } else {
            print("지문 인식 실패.");
            return false;
          }
        } else {
          print("세션이 만료되었습니다. 새로고침 시도.");
          try {
            final refreshedSession = await supabase.auth.refreshSession();
            if (refreshedSession.session != null) {
              print(
                  "세션 새로고침 성공. 새 만료 시간: ${DateTime.fromMillisecondsSinceEpoch(refreshedSession.session!.expiresAt! * 1000)}");
              // 세션 새로고침 후 지문 인식 시도
              return await _authenticateWithBiometrics();
            } else {
              print("세션 새로고침 실패: 새 세션이 null입니다.");
              return false;
            }
          } catch (e) {
            print("세션 새로고침 실패: $e");
            return false;
          }
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

  Future<bool> _authenticateWithBiometrics() async {
    final LocalAuthentication _localAuth = LocalAuthentication();

    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        print("이 기기에서는 생체 인증을 사용할 수 없습니다.");
        return false;
      }

      List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();
      print("사용 가능한 생체 인증 방식: $availableBiometrics");

      bool isFingerprint = false;

      if (Platform.isAndroid) {
        // Android의 경우
        isFingerprint =
            availableBiometrics.contains(BiometricType.fingerprint) ||
                (availableBiometrics.contains(BiometricType.strong) &&
                    await _localAuth.isDeviceSupported());
      } else if (Platform.isIOS) {
        // iOS의 경우
        isFingerprint = availableBiometrics.contains(BiometricType.fingerprint);
      }

      if (!isFingerprint) {
        print("이 기기에서는 지문 인증을 사용할 수 없습니다.");
        return false;
      }

      print("지문 인증 시도 중...");
      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason:
            Platform.isIOS ? '계속하려면 Touch ID를 사용하세요' : '지문을 인식하여 로그인해주세요',
        authMessages: Platform.isAndroid
            ? <AndroidAuthMessages>[
                AndroidAuthMessages(
                  signInTitle: '지문 인증',
                  cancelButton: '취소',
                  biometricHint: '센서에 손가락을 대세요',
                  biometricNotRecognized: '지문이 인식되지 않았습니다',
                  biometricSuccess: '지문이 인식되었습니다',
                  biometricRequiredTitle: '지문 인증이 필요합니다',
                ),
              ]
            : [],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        print("지문 인증 성공");
        return true;
      } else {
        print("지문 인증 실패 또는 취소");
        return false;
      }
    } on PlatformException catch (e) {
      print("지문 인증 중 플랫폼 오류 발생: ${e.message}");
      return false;
    } catch (e) {
      print("지문 인증 중 예상치 못한 오류 발생: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
