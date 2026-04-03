// Archivo: android/build.gradle.kts (RAÍZ DEL PROYECTO)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuración de directorios de construcción (Build Directory)
// Esto organiza dónde se guardan los archivos temporales de Flutter
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Asegura que el proyecto espere a que el módulo ':app' esté listo
subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea estándar para limpiar el proyecto (ejecutada con .\gradlew clean)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}