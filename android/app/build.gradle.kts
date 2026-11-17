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

// Reuse the exact original transparent mascot and app icon from the iOS asset catalog.
val iosAssets = rootProject.projectDir.parentFile.resolve("HydraLion/Assets.xcassets")
val hydraAssets = mapOf(
    "app_icon.png" to iosAssets.resolve("AppIcon.appiconset/AppIcon.png"),
    "mascot_idle.png" to iosAssets.resolve("MascotIdle.imageset/MascotIdle.png"),
    "mascot_blink.png" to iosAssets.resolve("MascotBlink.imageset/MascotBlink.png"),
    "mascot_drink.png" to iosAssets.resolve("MascotDrink.imageset/MascotDrink.png"),
    "mascot_cheers.png" to iosAssets.resolve("MascotCheers.imageset/MascotCheers.png"),
    "mascot_surprised.png" to iosAssets.resolve("MascotSurprised.imageset/MascotSurprised.png"),
    "mascot_relax.png" to iosAssets.resolve("MascotRelax.imageset/MascotRelax.png")
)

val copyHydraAssets = tasks.register("copyHydraAssets") {
    val outputFiles = hydraAssets.keys.map { layout.projectDirectory.file("src/main/res/drawable-nodpi/" + it) }
    inputs.files(hydraAssets.values)
    outputs.files(outputFiles)
    doLast {
        val destination = layout.projectDirectory.dir("src/main/res/drawable-nodpi").asFile
        destination.mkdirs()
        hydraAssets.forEach { (name, source) ->
            check(source.exists() && source.length() > 1024L) { "Missing original iOS asset: " + source.absolutePath }
            source.copyTo(destination.resolve(name), overwrite = true)
            logger.lifecycle("Bundled original HydraLion asset: " + name)
        }
    }
}
tasks.configureEach {
    if (name == "preBuild") dependsOn(copyHydraAssets)
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
