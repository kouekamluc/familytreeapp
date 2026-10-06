import java.util.Properties
import java.util.Base64
import java.net.URI

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties()
if (releasePropertiesFile.exists()) {
    releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name.contains("ProductionRelease", ignoreCase = true) } && !releasePropertiesFile.exists()) {
        throw GradleException("Configure your private Android release key in android/key.properties before creating a production release.")
    }
    if (allTasks.any { it.name.contains("ProductionRelease", ignoreCase = true) }) {
        val defines = (project.findProperty("dart-defines") as? String ?: "").split(",")
            .mapNotNull { encoded -> runCatching { String(Base64.getDecoder().decode(encoded)) }.getOrNull() }
        val configured = defines.firstOrNull { it.startsWith("API_BASE_URL=") }?.substringAfter("=")
        val uri = configured?.let { runCatching { URI(it) }.getOrNull() }
        if (uri == null || uri.scheme != "https" || uri.host.isNullOrBlank() ||
            uri.rawUserInfo != null || uri.rawQuery != null || uri.rawFragment != null ||
            uri.path != "/api" || uri.host in listOf("localhost", "127.0.0.1", "10.0.2.2")) {
            throw GradleException("Production requires --dart-define=API_BASE_URL=https://your-public-host/api with no credentials, query or fragment.")
        }
    }
}

android {
    namespace = "com.kkevo.flutter_frontend"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID matching the Kkevo Royal Family Tree
        applicationId = "com.kkevo.familytree"
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("production") { dimension = "environment" }
        create("audit") {
            dimension = "environment"
            applicationIdSuffix = ".audit"
        }
    }

    buildTypes {
        release {
            // Production packages must be signed with a private release key.
            // Keep signing credentials outside the repository.
            if (releasePropertiesFile.exists()) {
                signingConfig = signingConfigs.create("privateRelease") {
                    keyAlias = releaseProperties.getProperty("keyAlias")
                    keyPassword = releaseProperties.getProperty("keyPassword")
                    storeFile = file(releaseProperties.getProperty("storeFile"))
                    storePassword = releaseProperties.getProperty("storePassword")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
