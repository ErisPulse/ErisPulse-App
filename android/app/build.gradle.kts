import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.erispulse.erispulse_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // 启用 core library desugaring：flutter_local_notifications 依赖需要 Java 8+ API 在低版本 Android 上可用
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.erispulse.erispulse_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionName 来自 pubspec（如 0.2.5）
        versionName = flutter.versionName
        // versionCode 单调递增：以"天数×100"为基数，永远大于历史版本号。
        // 原因：pubspec 的 +N（如 0.2.5+1）长期未递增，设备上残留高
        // versionCode（如 2002）时会被拒装（INSTALL_FAILED_VERSION_DOWNGRADE）。
        // 同一天多次构建 code 相同，可覆盖重装（非降级）；跨天必然递增。
        versionCode =
            maxOf(flutter.versionCode, (System.currentTimeMillis() / 86400000 * 100).toInt())

        // arm64-only 由 CI 的 --split-per-abi 实现：只发布 arm64-v8a 分片 APK
        // （分片只含该 ABI 的引擎 / 插件 AAR / jniLibs）。注意不能用
        // ndk.abiFilters 过滤 universal：实测它对 Flutter 引擎 / 插件 AAR 库
        // 不生效（包内仍混入 32 位库），且与 --split-per-abi 冲突。
        // 纯 64 位设备（骁龙 8 Gen 3 / 天玑 9300 等）的 ROM 会拒绝安装含
        // 32 位 native lib 的 APK，因此必须保证产物无 32 位库。
    }

    signingConfigs {
        create("release") {
            // CI 通过 secrets 注入 keystore 与口令；本地未设置时回退 debug 签名
            val b64 = System.getenv("ANDROID_KEYSTORE_BASE64")
            if (!b64.isNullOrBlank()) {
                val keystoreFile =
                    layout.buildDirectory.file("release.keystore").get().asFile
                keystoreFile.parentFile?.mkdirs()
                keystoreFile.writeBytes(Base64.getDecoder().decode(b64))
                storeFile = keystoreFile
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // 有签名 secrets（CI）用正式签名，否则回退 debug（本地开发）
            val hasReleaseKey =
                !System.getenv("ANDROID_KEYSTORE_BASE64").isNullOrBlank()
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    // proot/busybox 作为 native lib 打包，需提取到文件系统才能 exec
    // （Android 10+ 默认 extractNativeLibs=false，native lib 只在 APK 内 mmap，无法 exec）
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
