import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciais de assinatura de release, carregadas de android/key.properties.
// O arquivo NÃO é versionado (ver .gitignore). Quando ausente, o build de
// release recorre à chave de debug (útil em desenvolvimento).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "br.gov.sp.detran.ritmo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Exigido por flutter_local_notifications 10+ para agendamento com
        // compatibilidade em versões antigas do Android.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.gov.sp.detran.ritmo"
        // minSdk 23 (Android 6): piso com notificações agendadas consistentes.
        // targetSdk e versão acompanham o Flutter (não fixados).
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Só cria a config de release quando há key.properties com storeFile.
        if (keystoreProperties.getProperty("storeFile") != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Assina com a chave de upload quando configurada; caso contrário,
            // recorre à chave de debug para que `flutter run --release` funcione
            // em desenvolvimento sem exigir o keystore.
            signingConfig = if (keystoreProperties.getProperty("storeFile") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
    // Suporte a APIs Java 8+ em versões antigas do Android, exigido por
    // flutter_local_notifications (agendamento de notificações).
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
