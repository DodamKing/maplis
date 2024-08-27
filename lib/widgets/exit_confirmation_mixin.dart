import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

mixin ExitConfirmationMixin<T extends StatefulWidget> on State<T> {
  DateTime? lastBackPressTime;
  static const exitTimeInMillis = 2000;

  Future<bool> showExitConfirmationDialog(bool didPop) async {
    if (didPop) return true;

    final now = DateTime.now();
    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(milliseconds: exitTimeInMillis)) {
      lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '한 번 더 누르면 너플리스와 잠시 작별이에요!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.eastSeaDokdo(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 0.2,),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: exitTimeInMillis),
          backgroundColor: Colors.purple.shade400.withOpacity(0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
          margin: const EdgeInsets.only(
            bottom: 20,
            left: 16,
            right: 16,
          ),
        ),
      );
      return false;
    }

    // 두 번째 뒤로 가기: 앱 종료
    return true;
  }

  Future<bool> handlePopInvoked(bool didPop) async {
    final shouldExit = await showExitConfirmationDialog(didPop);
    if (shouldExit) {
      await Future.delayed(const Duration(milliseconds: 300));
      // 앱 종료 로직
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
    return false; // 항상 false를 반환하여 시스템의 기본 뒤로 가기 동작을 방지
  }
}