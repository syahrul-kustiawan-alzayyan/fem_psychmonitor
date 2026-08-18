plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties from key.properties
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Patch whisper_kit CMakeLists.txt to remove armv8.2-a+fp16 flag that causes SIGILL on older devices
val pubCacheBase = System.getenv("PUB_CACHE") ?: "${System.getProperty("user.home")}/AppData/Local/Pub/Cache"
val whisperCmakeFile = file("$pubCacheBase/hosted/pub.dev/whisper_kit-0.3.1/src/CMakeLists.txt")
tasks.matching { it.name.startsWith("configureCMake") }.configureEach {
    doFirst {
        if (whisperCmakeFile.exists()) {
            var content = whisperCmakeFile.readText()
            val patched = content
                .replace("-march=armv8.2-a+fp16", "-march=armv8-a")
                .replace("-mfpu=neon-vfpv4", "-mfpu=neon")
            if (content != patched) {
                whisperCmakeFile.writeText(patched)
                logger.lifecycle("✅ Patched whisper_kit CMakeLists.txt for broader CPU compatibility")
            }
        }
    }
}

android {
    namespace = "com.fempsychmonitor"
    ndkVersion = "28.2.13676358"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.fempsychmonitor"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "")
            keyPassword = keystoreProperties.getProperty("keyPassword", "")
            val storeFilePath = keystoreProperties.getProperty("storeFile", "")
            if (storeFilePath.isNotEmpty()) {
                storeFile = rootProject.file(storeFilePath)
            }
            storePassword = keystoreProperties.getProperty("storePassword", "")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
