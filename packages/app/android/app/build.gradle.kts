plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseBuildRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Android release signing requires android/key.properties. " +
            "See docs/releasing.md for the required values.",
    )
}

val keystoreProperties = keystorePropertiesFile.takeIf { it.exists() }
    ?.readLines()
    ?.filter { it.isNotBlank() && !it.startsWith("#") }
    ?.associate { line ->
        val separator = line.indexOf('=')
        require(separator > 0) { "Invalid Android signing property: $line" }
        line.substring(0, separator) to line.substring(separator + 1)
    }
    .orEmpty()

fun signingProperty(name: String): String =
    keystoreProperties[name]?.takeIf { it.isNotBlank() }
        ?: throw GradleException("Missing Android signing property: $name")

android {
    // Quoted literal, not a `val`: the Flutter tool reads the namespace and the
    // application id out of this file with a regex instead of evaluating
    // Gradle, and a variable reference reads as absent. Without it,
    // `flutter test -d <android device>` cannot resolve the launch activity.
    // `app_identity_test.dart` holds both to the identity constant.
    namespace = "net.tinyrack.coder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "net.tinyrack.coder"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(signingProperty("storeFile"))
                storePassword = signingProperty("storePassword")
                keyAlias = signingProperty("keyAlias")
                keyPassword = signingProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (releaseBuildRequested) {
                signingConfig = signingConfigs.getByName("release")
            }
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
