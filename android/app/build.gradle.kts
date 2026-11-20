import java.util.Base64
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val buildDefines = (project.findProperty("dart-defines") as? String).orEmpty().split(",").filter { it.isNotBlank() }.associate {
    val pair = String(Base64.getDecoder().decode(it)).split("=", limit = 2)
    pair.first() to pair.getOrElse(1) { "" }
}
val appLinkHost = buildDefines["AUTH_APP_LINK_HOST"]?.lowercase()
    ?.takeIf { it.matches(Regex("[a-z0-9][a-z0-9.-]*[a-z0-9]")) } ?: "unconfigured.invalid"
val requiredReleaseDefines = listOf("APP_ENV", "SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY", "MAPBOX_PUBLIC_TOKEN", "FIREBASE_API_KEY", "FIREBASE_APP_ID", "FIREBASE_MESSAGING_SENDER_ID", "FIREBASE_PROJECT_ID", "AUTH_APP_LINK_HOST")
val requestedTasks = gradle.startParameter.taskNames.map { it.substringAfterLast(":").lowercase() }
val requestedFlavors = listOf("dev", "staging", "production").filter { flavor ->
    requestedTasks.any { it.contains(flavor + "debug") || it.contains(flavor + "release") }
}
// Flutter/AGP may execute preparatory tasks for sibling variants. Validate the
// explicitly requested flavor; aggregate multi-environment builds are unsafe.
if (requestedFlavors.size > 1 || requestedTasks.any { it in listOf("assembledebug", "assemblerelease", "bundlerelease") }) {
    throw GradleException("Build one explicit Android flavor with its matching APP_ENV")
}

android {
    namespace = "com.tricgabay.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        manifestPlaceholders["authAppLinkHost"] = appLinkHost
        applicationId = "com.tricgabay.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") { dimension = "environment"; applicationIdSuffix = ".dev"; manifestPlaceholders["appLabel"] = "Tric Gabay Dev" }
        create("staging") { dimension = "environment"; applicationIdSuffix = ".staging"; manifestPlaceholders["appLabel"] = "Tric Gabay Staging" }
        create("production") { dimension = "environment"; manifestPlaceholders["appLabel"] = "Tric Gabay" }
    }

    val signingProperties = Properties()
    val signingPropertiesFile = rootProject.file("key.properties")
    if (signingPropertiesFile.exists()) {
        signingProperties.load(FileInputStream(signingPropertiesFile))
    }

    signingConfigs {
        if (signingPropertiesFile.exists()) {
            create("release") {
                keyAlias = signingProperties["keyAlias"] as String
                keyPassword = signingProperties["keyPassword"] as String
                storeFile = file(signingProperties["storeFile"] as String)
                storePassword = signingProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingPropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    listOf("dev", "staging", "production").forEach { flavor ->
        val capitalized = flavor.replaceFirstChar { it.uppercase() }
        val validation = tasks.register("validate" + capitalized + "ReleaseConfiguration") {
            doLast {
                if (requestedFlavors.isNotEmpty() && flavor !in requestedFlavors) return@doLast
                val missing = requiredReleaseDefines.filter { buildDefines[it].isNullOrBlank() }
                if (missing.isNotEmpty()) throw GradleException("Missing release configuration: " + missing.joinToString(", "))
                if (buildDefines["APP_ENV"] != flavor) throw GradleException("APP_ENV must match the Android flavor: " + flavor)
                if (!buildDefines["SUPABASE_URL"]!!.startsWith("https://") || !buildDefines["MAPBOX_PUBLIC_TOKEN"]!!.startsWith("pk.")) throw GradleException("Invalid release service configuration")
                if (appLinkHost == "unconfigured.invalid") throw GradleException("A verified HTTPS authentication domain is required")
                if (!signingPropertiesFile.exists() && System.getenv("ALLOW_DEBUG_RELEASE_SIGNING") != "true") throw GradleException("Release signing is not configured. Configure the release keystore before distribution.")
            }
        }
        tasks.matching { it.name == "pre" + capitalized + "ReleaseBuild" }.configureEach { dependsOn(validation) }
        tasks.matching { it.name == "pre" + capitalized + "DebugBuild" }.configureEach {
            doFirst {
                if (requestedFlavors.isNotEmpty() && flavor !in requestedFlavors) return@doFirst
                val environment = buildDefines["APP_ENV"] ?: "dev"
                if (environment != flavor) throw GradleException("APP_ENV must match the Android flavor: " + flavor)
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
