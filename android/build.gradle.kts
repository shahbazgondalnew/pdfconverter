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

fun Project.forceCompileSdk36() {
    val android = extensions.findByName("android") as? groovy.lang.GroovyObject ?: return
    runCatching { android.setProperty("compileSdk", 36) }
    runCatching { android.invokeMethod("compileSdkVersion", arrayOf(36)) }
    runCatching { android.setProperty("compileSdkVersion", 36) }
}

// Force plugin modules onto compileSdk 36 (lifecycle AAR metadata requires it).
subprojects {
    pluginManager.withPlugin("com.android.library") {
        forceCompileSdk36()
        afterEvaluate { forceCompileSdk36() }
    }
    pluginManager.withPlugin("com.android.application") {
        forceCompileSdk36()
        afterEvaluate { forceCompileSdk36() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
