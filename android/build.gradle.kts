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
    val configureNamespace: (Project) -> Unit = { proj ->
        if (proj.hasProperty("android")) {
            val androidExt = proj.extensions.findByName("android")
            if (androidExt is com.android.build.api.dsl.LibraryExtension) {
                if (androidExt.namespace == null) {
                    val ns = proj.group.toString()
                    androidExt.namespace = if (ns.isNotEmpty() && ns != "null") ns else proj.name
                }
                androidExt.compileSdk = 36
                androidExt.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        proj.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
    if (project.state.executed) {
        configureNamespace(project)
    } else {
        project.afterEvaluate { configureNamespace(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
