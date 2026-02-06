# GitUtil Mobile Android APK

This directory contains the Android APK project for GitUtil Mobile.

## What is this APK?

This is a lightweight launcher/installer app that helps users get started with GitUtil Mobile on Android. It provides:

- Direct links to install Termux from F-Droid
- Direct links to download GitUtil packages from GitHub releases
- Quick access to setup documentation
- A beautiful Material Design interface

## Building the APK

### Prerequisites

- JDK 17 or higher
- Android SDK
- Gradle 8.2 or higher

### Build Commands

```bash
cd android

# Build unsigned debug APK
./gradlew assembleDebug

# Build unsigned release APK
./gradlew assembleRelease

# APK will be in: app/build/outputs/apk/release/
```

### CI/CD Build

The APK is automatically built by GitHub Actions when:
- Code is pushed to the `main` branch
- A version tag is created (e.g., `v1.0.0`)
- Manually triggered via workflow dispatch

See `.github/workflows/package-mobile.yml` for the build configuration.

## Project Structure

```
android/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── java/com/gitutil/mobile/
│   │       │   └── MainActivity.java          # Main activity
│   │       ├── res/
│   │       │   ├── layout/
│   │       │   │   └── activity_main.xml      # UI layout
│   │       │   ├── values/
│   │       │   │   ├── strings.xml            # String resources
│   │       │   │   ├── colors.xml             # Color definitions
│   │       │   │   └── themes.xml             # App theme
│   │       │   └── mipmap-*/                  # App icons
│   │       └── AndroidManifest.xml            # App manifest
│   └── build.gradle                           # App build config
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties          # Gradle version
├── build.gradle                               # Project build config
├── settings.gradle                            # Project settings
└── gradlew                                    # Gradle wrapper script
```

## Signing the APK

For production releases, the APK should be signed. GitHub Actions can automatically sign APKs if you configure these secrets:

- `SIGNING_KEY` - Base64-encoded keystore file
- `KEY_ALIAS` - Key alias
- `KEY_STORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password

If these secrets are not configured, the APK will be signed with the Android debug keystore, which allows it to be installed on devices for testing purposes. For production releases, it's recommended to configure the production signing secrets.

## Modifying the App

### Changing Colors

Edit `app/src/main/res/values/colors.xml`:

```xml
<color name="primary">#1976D2</color>
<color name="primary_dark">#1565C0</color>
```

### Updating Text

Edit `app/src/main/res/values/strings.xml`:

```xml
<string name="app_name">GitUtil Mobile</string>
```

### Changing Links

Edit `app/src/main/java/com/gitutil/mobile/MainActivity.java` and update the URLs in the methods:
- `openFDroidTermux()` - Termux F-Droid link
- `openGitHubReleases()` - GitHub releases link
- `openDocumentation()` - Documentation link

## Testing

1. Build the APK
2. Install on an Android device or emulator
3. Verify all buttons work and open correct URLs
4. Test on different Android versions (minimum API 24)

## License

Same as the parent GitUtil project.
