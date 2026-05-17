allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set root build directory to a 'build' folder sibling to the 'android' folder
rootProject.layout.buildDirectory.set(rootProject.projectDir.parentFile.resolve("build"))

subprojects {
    // Set each subproject's build directory to a subdirectory within the root build folder
    project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    
    // Disable Android Test variants for subprojects (plugins) as they are rarely needed
    // and often cause "Directory does not exist" errors with custom build directories in AGP 8.x+
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
