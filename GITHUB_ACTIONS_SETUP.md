# Paisa Mitra - GitHub Actions APK Build

## Build environment

- Flutter: 3.24.5
- Dart: 3.5.x (bundled with Flutter 3.24.5)
- Java: 17
- Android Gradle Plugin: 8.3.2
- Gradle: 8.10.2
- Kotlin: 2.1.0
- compileSdk: 35
- targetSdk: 35

## Note on Gradle/Kotlin/AGP versions

These were bumped from the original 8.1.1/8.2/1.9.24 combo because
recent Flutter SDK releases (3.4x+) ship a Gradle plugin
(`flutter_tools/gradle/FlutterPlugin.kt`) that fails to compile
("Unresolved reference: filePermissions/user/read/write") against
older AGP/Kotlin/Gradle toolchains. If your CI ever picks up a newer
Flutter version than the pinned 3.24.5 (e.g. because of a stale
Actions cache), this newer toolchain keeps the build working instead
of hitting that error. Always confirm the "Verify Flutter version"
step in Actions actually prints `3.24.5` — if it prints something
newer, clear the repo's Actions cache (Actions tab → Caches).

## GitHub steps

1. Create a private GitHub repository.
2. Upload the contents of this project so `pubspec.yaml` is at repository root.
3. Commit and push to `main`.
4. Open **Actions** in GitHub.
5. Select **Build Paisa Mitra Android APK**.
6. Choose **Run workflow** for a manual build, or push to `main` to trigger it automatically.
7. Open the successful workflow run.
8. Under **Artifacts**, download `PaisaMitra-release`.
9. Extract the ZIP and install `PaisaMitra-release.apk` on Android.

## First build

The workflow intentionally keeps `flutter analyze` non-blocking on the first build. Once the project builds successfully, remove `continue-on-error: true` from that step to make analysis errors fail CI.
