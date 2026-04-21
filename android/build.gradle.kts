allprojects {
    repositories {
        // 1. 修正的阿里云 Maven 镜像地址
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        // 如果你需要添加额外的仓库，确保 URL 完整
        // maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") } // 例如 Flutter 国内镜像
    }
}

// 2. 谨慎修改构建目录（除非必要，否则建议注释掉）
// val newBuildDir: Directory = rootProject.layout.buildDirectory
//     .dir("../../build")
//     .get()
// rootProject.layout.buildDirectory.value(newBuildDir)
//
// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }

// 3. 除非明确需要，否则移除对 :app 的强制评估依赖
// subprojects {
//     project.evaluationDependsOn(":app")
// }

// 4. 通常不需要自定义 clean 任务，Gradle 自带的已足够
// tasks.register<Delete>("clean") {
//     delete(rootProject.layout.buildDirectory)
// }