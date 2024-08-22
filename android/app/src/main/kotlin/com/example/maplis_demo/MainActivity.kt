package com.example.maplis_demo

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.maplis_demo/backButton"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "handleBackPress") {
                // Flutter 쪽에서 뒤로 가기 이벤트 처리를 요청
                onBackPressed()
                result.success(null)
            }
        }
    }

    override fun onBackPressed() {
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onBackPressed", null)
    }
}
