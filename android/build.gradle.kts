plugins {
    id("com.android.application") version "9.2.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set root build directory
rootProject.layout.buildDirectory.set(rootProject.projectDir.parentFile.resolve("build"))

subprojects {
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    
    val configureAndroid = Action<Project> {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.run {
            compileSdkVersion(36)
        }
    }
    
    if (state.executed) {
        configureAndroid.execute(this)
    } else {
        afterEvaluate {
            configureAndroid.execute(this)
        }
    }
    
    if (project.name != "app") {
        plugins.withId("com.android.library") {
            val androidComponents = project.extensions.findByType<com.android.build.api.variant.LibraryAndroidComponentsExtension>()
            androidComponents?.beforeVariants { variantBuilder ->
                variantBuilder.androidTest.enable = false
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val javaCompile = project.tasks.withType<JavaCompile>().firstOrNull()
        if (javaCompile != null) {
            val target = javaCompile.targetCompatibility
            if (target == "1.8" || target == "8") {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
            } else if (target == "11") {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            } else if (target == "17") {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            } else if (target == "21") {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}