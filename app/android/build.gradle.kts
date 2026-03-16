allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Pin kotlin-stdlib to the KGP version so transitive deps (e.g. kotlinx-coroutines
    // 1.10.2 → kotlin-stdlib 2.3.10) cannot upgrade it above what the compiler supports.
    configurations.all {
        resolutionStrategy.force(
            "org.jetbrains.kotlin:kotlin-stdlib:2.1.21",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.21",
            "org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.1.21",
            "org.jetbrains.kotlin:kotlin-stdlib-common:2.1.21",
            "com.google.maps.android:android-maps-utils:4.0.0"

        )
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
