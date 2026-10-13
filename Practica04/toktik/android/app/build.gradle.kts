import java.util.concurrent.TimeUnit

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.toktik"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.toktik"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Flutter launches the APK's fixed MAIN activity, not the seasonal alias that
// PackageManager currently enables. Prepare that entry BEFORE Flutter installs
// and starts a debug APK, including when the old app was force-stopped. Release
// builds and stored appearance preferences are unaffected.
val debugAdb = androidComponents.sdkComponents.adb
tasks.matching { it.name == "assembleDebug" }.configureEach {
    doLast {
        fun adb(vararg arguments: String): String? {
            return try {
                val process = ProcessBuilder(debugAdb.get().asFile.absolutePath, *arguments)
                    .redirectErrorStream(true).start()
                val timeout = if (arguments.contains("-W")) 45L else 10L
                if (!process.waitFor(timeout, TimeUnit.SECONDS)) {
                    process.destroyForcibly()
                    null
                } else {
                    val output = process.inputStream.bufferedReader().readText()
                    if (process.exitValue() == 0) output else null
                }
            } catch (_: Exception) { null }
        }
        val devices = adb("devices") ?: return@doLast
        for (line in devices.lineSequence()) {
            val fields = line.trim().split(Regex("\\s+"))
            if (fields.size != 2 || fields[1] != "device") continue
            val serial = fields[0]
            val installed = adb("-s", serial, "shell", "pm", "path", "com.example.toktik")
            if (installed?.contains("package:") != true) continue
            // End the previous Flutter process so a pending seasonal write cannot
            // disable the prepared entry again while the new APK is installing.
            adb("-s", serial, "shell", "am", "force-stop", "com.example.toktik")
            val prepared = adb("-s", serial, "shell", "am", "start", "-W", "-n",
                "com.example.toktik/.LauncherPreparationActivity")
            if (prepared == null) {
                throw GradleException("TokTik ($serial): ADB no respondió al preparar el launcher debug.")
            }
            if (prepared.contains("Error type 3")) {
                logger.warn("TokTik ($serial): APK antiguo sin helper debug. Instala el APK debug nuevo una vez y vuelve a ejecutar Flutter.")
                continue
            }
            if (prepared.contains("Error")) {
                throw GradleException("TokTik ($serial): no se pudo abrir el helper debug. ADB: $prepared")
            }
            // am start returns before onCreate; wait until the fixed entry resolves.
            var ready = false
            var lastResolved: String? = null
            repeat(10) {
                if (!ready) {
                    val resolved = adb("-s", serial, "shell", "cmd", "package", "query-activities",
                        "--brief", "-a", "android.intent.action.MAIN", "-c",
                        "android.intent.category.LAUNCHER", "-p", "com.example.toktik")
                    lastResolved = resolved
                    ready = resolved?.contains("com.example.toktik/.LauncherActivity") == true
                    if (!ready) Thread.sleep(200)
                }
            }
            if (!ready) throw GradleException("TokTik ($serial): no se pudo habilitar la actividad de inicio debug. ADB: $lastResolved")
            logger.lifecycle("TokTik ($serial): LauncherActivity preparada automáticamente para Flutter.")
        }
    }
}
