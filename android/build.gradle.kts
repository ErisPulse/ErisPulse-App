allprojects {
    repositories {
        // Aliyun 镜像优先（规避国内访问 maven.google.com 慢）；
        // CI（海外 runner）设置 USE_ALIYUN_MIRROR=false 跳过，走官方仓库
        if (System.getenv("USE_ALIYUN_MIRROR") != "false") {
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/public")
            maven("https://maven.aliyun.com/repository/central")
        }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // 插件模块 compileSdk 提升至 36：AAR 元数据检查要求插件 compileSdk 不低于其
    // 依赖 AAR 的 minCompileSdk（如 file_picker 8.3.7 硬编码 34，而
    // flutter_plugin_android_lifecycle 2.0.35 的 AAR minCompileSdk 为 36）
    val bumpCompileSdk: () -> Unit = {
        extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.let { lib ->
            if ((lib.compileSdk ?: 0) < 36) {
                lib.compileSdk = 36
            }
        }
    }
    if (state.executed) {
        bumpCompileSdk()
    } else {
        afterEvaluate { bumpCompileSdk() }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
