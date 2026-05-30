allprojects {
    repositories {
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
    project.evaluationDependsOn(":app")
}

// Workaround: firebase_analytics 12.4.1 skips applying kotlin-android when AGP >= 9
// (assumes android.builtInKotlin=true), but the Flutter 3.44 template ships with it
// false. Flutter's auto-applier also skips because the build.gradle text mentions
// kotlin-android (inside the AGP version check). Force-apply it here so the plugin's
// .kt sources actually compile.
subprojects {
    if (name == "firebase_analytics") {
        plugins.withId("com.android.library") {
            pluginManager.apply("kotlin-android")
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
