pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.application") version "8.7.0" apply false
        id("org.jetbrains.kotlin.android") version "1.8.0" apply false
        // Register the Google-Services plugin version here:
        id("com.google.gms.google-services") version "4.3.15" apply false
    }
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "com.google.gms.google-services") {
                // Tell Gradle how to map the plugin ID → Maven artifact
                useModule("com.google.gms:google-services:${requested.version}")
            }
        }
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "gov_citizen_app"
include(":app")
