
// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {

    extra.apply {
        set("kotlin_version", Versions.kotlin_version)
        set("compose_version", Versions.compose_version)
    }
    repositories {
        mavenLocal()
        //首选国外镜像加快github CI
        google()
        mavenCentral()
        maven("https://www.jitpack.io")
        // maven("https://120.25.164.233:8081/nexus/content/groups/public/") // 原作者私人 nexus，已不可达，注释改走公共源
        maven("https://maven.aliyun.com/repository/central")
        google { url = uri("https://maven.aliyun.com/repository/google") }
        mavenCentral { url = uri("https://maven.aliyun.com/repository/public") }
        maven("https://maven.aliyun.com/repository/jcenter") // jcenter 缓存源
        maven("https://repo.huaweicloud.com/repository/maven/") // 华为云镜像（含 jcenter 副本），RootShell:1.6 等老库从此取
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.6.0")
        classpath(kotlin("gradle-plugin", version = Versions.kotlin_version))
        classpath("com.jakewharton:butterknife-gradle-plugin:10.2.3")
        classpath("org.codehaus.groovy:groovy-json:3.0.8")
        classpath("com.yanzhenjie.andserver:plugin:2.1.12")
        classpath(libs.okhttp)
    }
}

allprojects {
    repositories {
        mavenLocal()
        //首选国外镜像加快github CI
        google()
        mavenCentral()
        maven("https://www.jitpack.io")
        // maven("https://120.25.164.233:8081/nexus/content/groups/public/") // 原作者私人 nexus，已不可达，注释改走公共源
        maven("https://maven.aliyun.com/repository/central")
        google { url = uri("https://maven.aliyun.com/repository/google") }
        mavenCentral { url = uri("https://maven.aliyun.com/repository/public") }
        maven("https://maven.aliyun.com/repository/jcenter") // jcenter 缓存源
        maven("https://repo.huaweicloud.com/repository/maven/") // 华为云镜像（含 jcenter 副本），RootShell:1.6 等老库从此取
    }
//    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java){
//        kotlinOptions{
//            freeCompilerArgs = freeCompilerArgs.toMutableList().apply {
//                add("-P")
//                add("plugin:androidx.compose.compiler.plugins.kotlin:suppressKotlinVersionCompatibilityCheck=true")
//            }
//        }
//    }

}

tasks.register<Delete>("clean").configure {
    delete(rootProject.buildDir)
}
