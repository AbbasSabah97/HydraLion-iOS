import java.net.URL

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.abbassabah.hydralion"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.abbassabah.hydralion"
        minSdk = 23
        targetSdk = 30
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

// The Android build packages the exact transparent mascot PNGs and app icon
// from the companion iOS project. They are downloaded at build time and are
// bundled into the APK, so the installed app works completely offline.
val hydraAssetBase = "https://raw.githubusercontent.com/AbbasSabah97/HydraLion-iOS/main/HydraLion/Assets.xcassets"
val hydraAssets = mapOf(
    "app_icon.png" to "$hydraAssetBase/AppIcon.appiconset/AppIcon.png",
    "mascot_idle.png" to "$hydraAssetBase/MascotIdle.imageset/MascotIdle.png",
    "mascot_blink.png" to "$hydraAssetBase/MascotBlink.imageset/MascotBlink.png",
    "mascot_drink.png" to "$hydraAssetBase/MascotDrink.imageset/MascotDrink.png",
    "mascot_cheers.png" to "$hydraAssetBase/MascotCheers.imageset/MascotCheers.png",
    "mascot_surprised.png" to "$hydraAssetBase/MascotSurprised.imageset/MascotSurprised.png",
    "mascot_relax.png" to "$hydraAssetBase/MascotRelax.imageset/MascotRelax.png"
)

val downloadHydraAssets = tasks.register("downloadHydraAssets") {
    val outputFiles = hydraAssets.keys.map { layout.projectDirectory.file("src/main/res/drawable-nodpi/$it") }
    outputs.files(outputFiles)
    doLast {
        val destination = layout.projectDirectory.dir("src/main/res/drawable-nodpi").asFile
        destination.mkdirs()
        hydraAssets.forEach { (name, url) ->
            val target = destination.resolve(name)
            if (!target.exists() || target.length() < 1024L) {
                logger.lifecycle("Downloading HydraLion asset: $name")
                val connection = URL(url).openConnection()
                connection.connectTimeout = 30000
                connection.readTimeout = 60000
                connection.getInputStream().use { input -> target.outputStream().use { output -> input.copyTo(output) } }
                check(target.length() > 1024L) { "Asset download failed: $name" }
            }
        }
    }
}
tasks.configureEach {
    if (name == "preBuild") dependsOn(downloadHydraAssets)
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
    implementation("com.google.code.gson:gson:2.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    debugImplementation("androidx.compose.ui:ui-tooling")
}
