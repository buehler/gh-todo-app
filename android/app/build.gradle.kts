import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.apollographql.apollo")
}

android {
    namespace = "ch.cbue.gh_todos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "ch.cbue.gh_todos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("CM_KEY_ALIAS")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            storeFile = System.getenv("CM_KEYSTORE_PATH")?.let { file(it) }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
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

val prepareApolloSchema by tasks.registering {
    val source = file("../../lib/graphql/schema.graphql")
    val target = layout.buildDirectory.file("generated/apollo/schema.graphqls")
    inputs.file(source)
    outputs.file(target)
    doLast {
        target.get().asFile.parentFile.mkdirs()
        source.copyTo(target.get().asFile, overwrite = true)
    }
}

apollo {
    service("widget") {
        packageName.set("ch.cbue.gh_todos.widget.graphql")
        schemaFiles.from(prepareApolloSchema)
        srcDir("src/main/graphql")
        mapScalar("Date", "kotlin.String", "com.apollographql.apollo.api.StringAdapter")
        mapScalar("DateTime", "kotlin.String", "com.apollographql.apollo.api.StringAdapter")
    }
}

dependencies {
    implementation("com.apollographql.apollo:apollo-runtime:5.2.0")
    implementation("androidx.work:work-runtime-ktx:2.12.0")
}
