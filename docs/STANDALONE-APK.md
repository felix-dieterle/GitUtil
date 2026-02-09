# GitUtil Android Implementation

## Overview

GitUtil Mobile is a **standalone Android application** that provides full git repository management without requiring any external dependencies.

## Architecture

### Technology Stack

- **JGit (Eclipse JGit 6.7.0)** - Pure Java implementation of Git
- **WebView** - Embedded browser for displaying the touch-optimized HTML interface
- **JavaScript Bridge** - Communication layer between HTML UI and native Java code
- **Asset-based UI** - Self-contained HTML interface bundled with the app

### Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     GitUtil Mobile APK                   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐         ┌─────────────────────┐       │
│  │  MainActivity │────────▶│  GitUtilActivity    │       │
│  │  (Launcher)   │         │  (WebView Container)│       │
│  └──────────────┘         └──────────┬──────────┘       │
│                                       │                   │
│                            ┌──────────▼──────────┐       │
│                            │   touch-ui.html      │       │
│                            │   (Asset)            │       │
│                            └──────────┬──────────┘       │
│                                       │                   │
│                                       │ JavaScript        │
│                                       │ Interface         │
│                                       │                   │
│                            ┌──────────▼──────────┐       │
│                            │    GitBridge         │       │
│                            │    (Java)            │       │
│                            └──────────┬──────────┘       │
│                                       │                   │
│                            ┌──────────▼──────────┐       │
│                            │      JGit            │       │
│                            │  (Git Operations)    │       │
│                            └─────────────────────┘       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Key Components

### 1. GitBridge.java

The bridge between JavaScript and JGit. Provides three main operations:

- **check-location** - Validates if a path contains a valid git repository
- **pull-timeline** - Fetches commit history (up to 100 commits)
- **apply-rollback** - Performs hard reset to a specific commit

Each operation returns a JSON response compatible with the original Python bridge format.

### 2. GitUtilActivity.java

WebView container that:
- Loads the HTML interface from assets
- Injects the GitBridge as a JavaScript interface
- Handles storage permission requests
- Manages WebView lifecycle

### 3. touch-ui.html (Modified)

The original HTML interface with automatic detection:

```javascript
// Check if AndroidBridge is available (native Android)
if(typeof AndroidBridge !== 'undefined'){
    const result = AndroidBridge.executeWrapper(wrapperName, JSON.stringify(args));
    return JSON.parse(result);
}
// No fallback needed - app always has AndroidBridge
```

This allows the interface to use AndroidBridge for native git operations.

## Implementation Details

### Git Operations Using JGit

#### Repository Validation

```java
FileRepositoryBuilder builder = new FileRepositoryBuilder();
Repository repository = builder
    .setGitDir(new File(path, ".git"))
    .readEnvironment()
    .findGitDir()
    .build();
```

#### Fetching Commits

```java
try (Git git = new Git(repository)) {
    Iterable<RevCommit> commits = git.log().setMaxCount(100).call();
    for (RevCommit commit : commits) {
        // Format as SNAPSHOT_BEGIN/END blocks
    }
}
```

#### Hard Reset

```java
git.reset()
    .setMode(ResetCommand.ResetType.HARD)
    .setRef(commitHash)
    .call();
```

### JavaScript Bridge Pattern

The AndroidBridge is injected into the WebView:

```java
webView.addJavascriptInterface(gitBridge, "AndroidBridge");
```

And exposed via the `@JavascriptInterface` annotation:

```java
@JavascriptInterface
public String executeWrapper(String wrapperName, String argsJson) {
    // Parse args and execute git operations
}
```

### Permissions

The app requires storage permissions to access git repositories:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

These are requested at runtime when GitUtilActivity launches.

## Advantages

### No External Dependencies

- **Self-contained** - Runs natively on Android
- **Pure Java** - JGit handles all git operations
- **No HTTP server** - Direct JavaScript to Java communication

### Better Integration

- **Native permissions** - Standard Android permission dialogs
- **Faster startup** - No need to launch external processes
- **Better security** - No localhost HTTP server needed
- **Offline capable** - Everything runs locally

### Smaller Footprint

- **Single APK** - ~10 MB including JGit
- **No additional packages** - Self-contained
- **Faster installation** - No pkg install steps

## Compatibility

### Supported Operations

All core operations from the shell script version:
- ✅ Repository validation
- ✅ Commit history browsing (100 commits)
- ✅ Hard reset to commit
- ✅ Repository cloning
- ✅ Workspace management
- ✅ Path persistence
- ✅ Confirmation dialogs

### Technical Limitations

The app is limited to JGit capabilities:
- No custom git commands
- No access to shell tools
- Cannot run custom scripts

For most users, the app provides all needed git functionality.

## Building

Add JGit dependency in `app/build.gradle`:

```gradle
dependencies {
    implementation 'org.eclipse.jgit:org.eclipse.jgit:6.7.0.202309050840-r'
    // ... other dependencies
}
```

Build the APK:

```bash
cd android
./gradlew assembleRelease
```

## Testing

### Manual Testing

1. Build and install APK on Android device
2. Launch app and tap "Launch GitUtil"
3. Grant storage permission
4. Navigate to a git repository on device storage
5. Verify commit list loads
6. Test rollback operation

### Test Repositories

Good test paths on Android:
- `/sdcard/git/my-repo` - User-created repos
- `/storage/emulated/0/repos/test` - Emulated storage

## Future Enhancements

Potential improvements:

- **Branch management** - Switch branches, create branches
- **Staging area** - Add/remove files, create commits
- **Remote operations** - Fetch, pull, push (requires auth)
- **Diff viewing** - Show file changes
- **Merge support** - Handle merges and conflicts
- **Tag management** - Create and view tags
- **Stash support** - Stash and apply changes

All of these are possible with JGit without adding dependencies.

## Conclusion

The APK implementation successfully provides a fully functional git repository manager that:
- Requires no external dependencies
- Works entirely within a single APK
- Provides a touch-optimized mobile interface
- Offers seamless repository management

This makes GitUtil Mobile accessible to anyone with an Android device.
