# Flutter Android client

This repository includes the Flutter application source. The Flutter SDK is required to generate platform files and build an APK:

```sh
cd mobile
flutter create --platforms=android .
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:8000
flutter build apk --release --dart-define=API_URL=https://YOUR-API.onrender.com
```

Add `<uses-permission android:name="android.permission.INTERNET" />`, `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`, and `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />` to `android/app/src/main/AndroidManifest.xml` after generating Android files. Use HTTPS for release builds. The resulting APK is `build/app/outputs/flutter-apk/app-release.apk`.

The app offers registration, login, dashboard, camera/gallery selection, GPS location, report submission with AI result, and report history. The API URL defaults to the Android emulator loopback address; pass a reachable HTTPS URL for physical devices.
