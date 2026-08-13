import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('erispulse/native');
const _kNativeLibDirKey = 'erispulse.native_lib_dir';

/// native lib 目录（APK 中 jniLibs 打包的 .so 被系统提取到这里）。
///
/// Android 上只有该目录（apk_data_file context）允许 untrusted_app 直接执行，
/// 所以 proot / busybox 必须从此处运行，而不是 app 私有目录（app_data_file
/// 缺少 execute_no_trans 权限）。
///
/// 注意：method channel handler 只注册在主 isolate 的 engine 上（MainActivity），
/// FGS 后台 isolate 无法直接调用。因此主 isolate 调用后缓存到 SharedPreferences，
/// FGS 通过 [readNativeLibraryDir] 读取。
Future<String> getNativeLibraryDir() async {
  try {
    final dir = await _channel.invokeMethod<String>('nativeLibraryDir');
    return dir ?? '';
  } catch (_) {
    return '';
  }
}

/// 主 isolate 获取到后缓存，供 FGS isolate 读取
Future<void> cacheNativeLibraryDir(String dir) async {
  if (dir.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNativeLibDirKey, dir);
  } catch (_) {}
}

/// FGS isolate 读取缓存的 native lib 目录
Future<String> readNativeLibraryDir() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNativeLibDirKey) ?? '';
  } catch (_) {
    return '';
  }
}
