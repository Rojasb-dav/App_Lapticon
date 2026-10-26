System.clearProperty("ANDROID_PREFS_ROOT")
try {
    val envMap = System.getenv()
    val mapField = envMap.javaClass.getDeclaredField("m")
    mapField.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    (mapField.get(envMap) as? MutableMap<String, String>)?.remove("ANDROID_PREFS_ROOT")
} catch (_: Exception) {}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
