# GitUtil - Git Branch Rewind Tool

[![Test Suite](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml/badge.svg)](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml)

A cross-platform git repository manager with **mobile web interface for Android** and interactive terminal UI.

GitUtil provides shell-based tools for navigating commit history and reverting branches, with two user interfaces:
- **Mobile Web UI** - Touch-optimized interface for Android devices (Termux)
- **Terminal UI** - Interactive command-line interface for desktop/server use

## Features

### Mobile Web Interface (Android/Termux)
- **Touch-optimized design** - Large buttons and responsive layout for mobile screens
- **Self-contained HTML** - Works offline, no internet required
- **Visual commit browser** - Scroll through commit history with full details
- **One-tap rollback** - Select any snapshot and reset your branch
- **Path memory** - Remembers your last repository location
- **Safe operations** - Confirmation dialogs before destructive actions

### Terminal Interface (Desktop/Server)
- **Interactive menus** - User-friendly numbered options
- **Repository browser** - Select and validate git repositories
- **Color-coded output** - Visual feedback for success/warning/info messages
- **Full commit details** - View hash, author, timestamp, and message

### Core Features
- Browse git repositories on any device
- View complete commit timeline
- Revert branch to any historical commit
- Safe operations with confirmation prompts

## Project Structure

This project uses a lightweight shell-based architecture:
- `gitutil.sh` - Interactive terminal UI (desktop/server interface)
- `mobile/` - **Mobile web interface for Android**
  - `touch-ui.html` - Mobile-optimized HTML interface
  - `launch-mobile.sh` - Launcher script for Termux
  - `wrappers/` - Shell script wrappers (auto-generated)
- `scripts/` - Core git operation shell scripts
  - `validate_repo.sh` - Validates git repositories
  - `fetch_commits.sh` - Extracts commit history
  - `revert_branch.sh` - Reverts branch to specific commit
- `tests/` - Comprehensive test suite for all scripts
- `docs/` - Architecture and integration documentation

## Installation & Usage

### Mobile Interface (Android/Termux)

**Option 1: Standalone APK (Recommended - No Dependencies Required)**

1. Download and install the GitUtil Mobile APK from [GitHub Releases](https://github.com/felix-dieterle/GitUtil/releases)
2. Open the app and tap "Launch GitUtil"
3. Grant storage permission when prompted
4. Enter your git repository path (e.g., `/sdcard/repos/my-project`)
5. Browse commits and rollback as needed

**The APK now includes built-in git support using JGit - no Termux, Python, or external dependencies required!**

**Option 2: Easy Install (Classic - Via Termux)**

1. Download and install the GitUtil Mobile APK from [GitHub Releases](https://github.com/felix-dieterle/GitUtil/releases)
2. Open the app and follow the on-screen installation guide
3. The app will help you:
   - Install Termux from F-Droid
   - Download the GitUtil package
   - Access setup documentation

**Option 3: Manual Installation (Termux)**

**Prerequisites:**
1. Install [Termux](https://f-droid.org/en/packages/com.termux/) from F-Droid
2. Install required packages:
   ```bash
   pkg install git bash python
   ```

**Quick Start:**
```bash
# Download and extract GitUtil
unzip gitutil-mobile-*.zip
cd gitutil-mobile-*

# Launch the mobile interface
bash mobile/launch-mobile.sh
```

The launcher will:
- Generate wrapper scripts automatically
- Start the bridge server on localhost:8765
- Open the interface in your browser

**Using the Mobile Interface:**
1. Enter your git repository path (e.g., `/sdcard/repos/my-project`)
2. Tap "Verify Location" to validate and load the repository
3. Browse through commit snapshots in the timeline
4. Tap a snapshot to select it
5. Tap "Apply Rollback" to reset your branch to that snapshot
6. Confirm the operation when prompted

**Important Notes:**
- Keep the terminal open - the bridge server must run while using the interface
- Press Ctrl+C to stop the server when done
- The interface connects to http://localhost:8765

**Tips:**
- Bookmark http://localhost:8765 for quick access
- The interface remembers your last repository path
- Works with any git repository on your device
- The bridge server provides secure localhost-only access

### Terminal Interface (Desktop/Server)

The easiest way to use GitUtil on desktop/server is through the interactive terminal interface:

```bash
# Launch the interactive UI
./gitutil.sh

# Or specify a repository path directly
./gitutil.sh /path/to/your/repo
```

The interactive UI provides:
- **Menu-based navigation** - Simple numbered options
- **Repository browser** - Select and validate git repositories
- **Commit timeline** - View commit history with full details
- **Safe branch revert** - Confirmation prompts before destructive operations
- **Color-coded output** - Visual feedback with success/warning/info messages

#### UI Features:
1. **Select repository** - Browse and validate git repositories on your system
2. **View commit history** - See all commits with hash, author, timestamp, and message
3. **Revert branch to commit** - Safely reset your branch to any previous commit
4. **Exit** - Close the application

### Direct Script Usage

You can also call the scripts directly:

```bash
# Validate a repository
./scripts/validate_repo.sh /path/to/repo

# Fetch commit history
./scripts/fetch_commits.sh /path/to/repo

# Revert to a specific commit
./scripts/revert_branch.sh /path/to/repo <commit-hash>
```

## Testing

The project includes a comprehensive test suite for all shell scripts. Tests run automatically via GitHub Actions on every push and pull request.

```bash
# Run all tests locally
./tests/run_tests.sh

# Run individual test files
./tests/test_validate_repo.sh
./tests/test_fetch_commits.sh
./tests/test_revert_branch.sh
```

See [tests/README.md](tests/README.md) for detailed testing documentation.

### Continuous Integration

Tests are automatically run on:
- Every push to `main` or `master` branches
- Every pull request targeting `main` or `master`

The CI workflow runs all 30 tests and reports results. Check the [Actions tab](https://github.com/felix-dieterle/GitUtil/actions) for test results.

## Requirements

### For Mobile Interface (Android)

**For Standalone APK (No Dependencies):**
- Android 7.0 (API 24) or higher
- Storage permission (granted when you first launch the app)
- About 10 MB of storage space
- That's it! No Termux, Python, or Git installation required

**For APK Users (Classic Termux Setup):**
- Android 7.0 (API 24) or higher
- Enable installation from unknown sources:
  - **Android 8.0+**: Settings → Apps → Special app access → Install unknown apps → [Your Browser] → Allow
  - **Android 7.x**: Settings → Security → Unknown Sources
- The APK will guide you through the rest of the setup

**For Manual Installation:**
- Android device with Termux installed
- Git, Bash, and Python 3 packages (`pkg install git bash python`)
- Web browser (any Android browser)
- Storage access for git repositories

### For Terminal Interface (Desktop/Server)
- Bash shell (version 4.0 or higher)
- Git command-line tools
- Terminal with color support (recommended)