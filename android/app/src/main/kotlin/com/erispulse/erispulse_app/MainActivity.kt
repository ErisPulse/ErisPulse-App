package com.erispulse.erispulse_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 暴露 native lib 目录：proot/busybox 作为 native lib 打包，
        // 只有该目录（apk_data_file）允许 untrusted_app 执行（execute_no_trans）。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "erispulse/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "nativeLibraryDir" -> result.success(applicationInfo.nativeLibraryDir)
                    else -> result.notImplemented()
                }
            }
    }
}
