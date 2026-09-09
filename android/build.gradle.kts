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

fun configureSubprojectAndroid(proj: Project) {
    val android = proj.extensions.findByName("android") ?: return
    for (method in android.javaClass.methods) {
        if ((method.name == "compileSdkVersion" || method.name == "setCompileSdk") && method.parameterCount == 1) {
            val paramType = method.parameterTypes[0]
            try {
                if (paramType == Int::class.javaPrimitiveType || paramType == java.lang.Integer::class.java) {
                    method.invoke(android, 36)
                } else if (paramType == String::class.java) {
                    method.invoke(android, "android-36")
                }
            } catch (_: Exception) {}
        }
    }
}

subprojects {
    if (project.state.executed) {
        configureSubprojectAndroid(project)
    } else {
        project.afterEvaluate {
            configureSubprojectAndroid(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

