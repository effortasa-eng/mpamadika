# Mpamadika (Android, tsy mila internet)

## 1. Manamboatra ny tetikasa
    flutter create --org mg.mpamadika --project-name mpamadika .
    # soloy ny lib/main.dart sy pubspec.yaml amin'ireo
    flutter pub get

## 2. android/app/build.gradle
Ao amin'ny defaultConfig : `minSdkVersion 23`  (na `minSdk = 23`)

## 3. android/app/src/main/AndroidManifest.xml
Ao anatin'ny <manifest>, alohan'ny <application> :

    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE"/>
    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
    <uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" android:usesPermissionFlags="neverForLocation"/>

## 4. Manamboatra ny APK
    flutter build apk --release
    # build/app/outputs/flutter-apk/app-release.apk

Zarao amin'ny Bluetooth / Xender / ShareIt ny APK.
Ampandehano ny Localisation (GPS) amin'ny telefaona rehetra rehefa milalao.
