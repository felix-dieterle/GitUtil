# GitUtil Mobile Android APK

This directory contains the Android APK project for GitUtil Mobile.

## What is this APK?

**Standalone Git Functionality!**

This is a fully functional Android app that provides git repository management without any external dependencies. The app includes:

- **Built-in Git Operations** - Uses JGit library for native git support
- **Touch-Optimized UI** - Beautiful WebView-based interface for managing repositories
- **No External Dependencies** - Works standalone without needing any external tools
- **Offline Capable** - All operations work locally on your device
- **Storage Access** - Direct access to git repositories on your device

## Features

- Browse git commit history with full details
- Rollback branches to any previous commit
- Clone repositories directly from URLs
- Touch-friendly interface optimized for mobile
- Works with any git repository on your device
- Repository browser for managing multiple repositories
- Automatic workspace creation at `/sdcard/GitUtil/repos`
- Confirmation dialogs for destructive operations

### Technical Architecture
- **JGit Integration** - Eclipse JGit library for pure Java git operations
- **WebView Bridge** - JavaScript bridge connecting HTML UI to native git operations
- **Asset-Based UI** - Self-contained HTML interface loaded from app assets
- **Permission Management** - Requests storage permissions for repository access

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
│   │       ├── assets/
│   │       │   └── touch-ui.html              # Mobile interface (embedded)
│   │       ├── java/com/gitutil/mobile/
│   │       │   ├── MainActivity.java          # Main launcher activity
│   │       │   ├── GitUtilActivity.java       # WebView-based git interface
│   │       │   └── GitBridge.java             # JavaScript bridge to JGit
│   │       ├── res/
│   │       │   ├── layout/
│   │       │   │   └── activity_main.xml      # UI layout
│   │       │   ├── values/
│   │       │   │   ├── strings.xml            # String resources
│   │       │   │   ├── colors.xml             # Color definitions
│   │       │   │   └── themes.xml             # App theme
│   │       │   └── mipmap-*/                  # App icons
│   │       └── AndroidManifest.xml            # App manifest
│   └── build.gradle                           # App build config (includes JGit)
├── gradle/
│   └── wrapper/
│       └── gradle-wrapper.properties          # Gradle version
├── build.gradle                               # Project build config
├── settings.gradle                            # Project settings
└── gradlew                                    # Gradle wrapper script
```

## Dependencies

The app uses the following key dependencies:

- **AndroidX AppCompat** - Backward compatibility
- **Material Components** - Material Design UI
- **ConstraintLayout** - Flexible layouts
- **Eclipse JGit (6.7.0)** - Pure Java git implementation

No Python, Bash, or external git binaries required!

## Signing the APK

For production releases, the APK should be signed. GitHub Actions can automatically sign APKs if you configure these secrets:

- `SIGNING_KEY` - Base64-encoded keystore file
- `KEY_ALIAS` - Key alias
- `KEY_STORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password

If these secrets are not configured, the APK will be signed with the Android debug keystore, which allows it to be installed on devices for testing purposes. For production releases, it's recommended to configure the production signing secrets.

## Modifying the App

### Adding New Git Operations

To add new git operations, update `GitBridge.java`:

```java
@JavascriptInterface
public String executeWrapper(String wrapperName, String argsJson) {
    // Add new case for your operation
    case "your-operation":
        return yourOperation(args.getString(0));
}
```

Then update `touch-ui.html` to call the new operation via `callWrapper()`.

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

## Using the App

1. **Install the APK** on your Android device (API 24+)
2. **Launch GitUtil** and tap "🚀 Launch GitUtil" button
3. **Grant storage permission** when prompted
4. **Choose an option:**
   - Clone a repository from a URL
   - Browse existing repositories in the workspace
   - Enter a custom repository path
5. **Browse commits** and rollback as needed

The app automatically manages your repositories in `/sdcard/GitUtil/repos`.

## Testing

1. Build the APK
2. Install on an Android device or emulator
3. Verify all buttons work and open correct URLs
4. Test on different Android versions (minimum API 24)

## License

Same as the parent GitUtil project.
