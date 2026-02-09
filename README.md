# GitUtil - Git Branch Rewind Tool

[![Test Suite](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml/badge.svg)](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml)

A cross-platform git repository manager with **mobile app for Android** and interactive terminal UI.

GitUtil provides shell-based tools for navigating commit history and reverting branches, with two user interfaces:
- **Mobile App** - Touch-optimized interface for Android devices with built-in git support
- **Terminal UI** - Interactive command-line interface for desktop/server use

## Features

### Mobile App (Android)
- **Touch-optimized design** - Large buttons and responsive layout for mobile screens
- **Built-in git support** - Uses JGit, no external dependencies required
- **Visual commit browser** - Scroll through commit history with full details
- **One-tap rollback** - Select any snapshot and reset your branch
- **Clone repositories** - Clone directly from GitHub/GitLab URLs
- **Repository browser** - Switch between multiple repositories effortlessly
- **Automatic workspace** - Manages repositories in `/sdcard/GitUtil/repos`
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
- **Automatic backup branches** - Creates timestamped backup branches before rollback
- Safe operations with confirmation prompts

## Project Structure

This project uses a lightweight shell-based architecture:
- `gitutil.sh` - Interactive terminal UI (desktop/server interface)
- `android/` - **Mobile Android app with built-in git support**
  - `MainActivity.java` - App launcher
  - `GitUtilActivity.java` - WebView container for the mobile UI
  - `GitBridge.java` - JGit integration for git operations
  - `touch-ui.html` - Mobile-optimized HTML interface
- `scripts/` - Core git operation shell scripts
  - `validate_repo.sh` - Validates git repositories
  - `fetch_commits.sh` - Extracts commit history
  - `revert_branch.sh` - Reverts branch to specific commit
  - `prepare_repo.sh` - Prepares repository (clones if URL)
  - `cleanup_repo.sh` - Deletes repository from workspace
- `tests/` - Comprehensive test suite for all scripts
- `docs/` - Architecture and integration documentation

## Installation & Usage

### Mobile App (Android)

1. Download and install the GitUtil Mobile APK from [GitHub Releases](https://github.com/felix-dieterle/GitUtil/releases)
2. Open the app and tap **"🚀 Launch GitUtil"**
3. Grant storage permission when prompted
4. **Automatic Workspace Setup:**
   - The app automatically creates a workspace at `/sdcard/GitUtil/repos`
   - Clone repositories directly from GitHub/GitLab URLs
   - Or browse to existing repositories on your device
5. Select a repository from the list or clone a new one
6. Browse commits and rollback as needed

**The APK includes built-in git support using JGit - no external dependencies required!**

**Features:**
- 🎯 **No manual setup required** - app manages workspace automatically
- 📦 **Clone repositories with one tap** - just paste the URL
- 📂 **Repository browser** - easily switch between multiple repositories
- 💾 **Automatic workspace creation** - everything stored in `/sdcard/GitUtil/repos`
- 🔄 **Remember last used repo** - quick access to your recent work

**Using the Mobile App:**
1. On first launch, the app automatically creates workspace at `/sdcard/GitUtil/repos`
2. Choose one of three options:
   - **Clone Repository**: Enter a Git URL (e.g., `https://github.com/user/repo.git`) and tap Clone
   - **Browse Workspace**: Select from repositories already in your workspace
   - **Custom Path**: Manually enter a repository path anywhere on your device
3. Browse through commit snapshots in the timeline
4. Tap a snapshot to select it
5. Tap "Apply Rollback" to reset your branch to that snapshot
6. Confirm the operation when prompted

**Tips:**
- The app automatically creates and manages `/sdcard/GitUtil/repos` workspace
- Clone repositories with just a URL - no manual path configuration needed
- The interface remembers your last used repository for quick access
- Switch between multiple repositories effortlessly with the repository browser
- Works with any git repository on your device

### Terminal Interface (Desktop/Server)

The easiest way to use GitUtil on desktop/server is through the interactive terminal interface:

```bash
# Launch the interactive UI
./gitutil.sh

# Or specify a repository path directly
./gitutil.sh /path/to/your/repo

# Or specify a remote repository URL (it will be cloned automatically)
./gitutil.sh https://github.com/user/repo.git
```

The interactive UI provides:
- **Menu-based navigation** - Simple numbered options
- **Repository browser** - Select and validate git repositories
- **Auto-clone support** - Automatically clone remote repositories
- **Default workspace** - Repositories cloned to `~/.gitutil/repos/` by default
- **Commit timeline** - View commit history with full details
- **Safe branch revert** - Automatic backup branches created before rollback operations
- **Color-coded output** - Visual feedback with success/warning/info messages

#### UI Features:
1. **Select repository** - Browse and validate git repositories on your system, or provide a remote URL
   - Local paths: `/path/to/repo`, `~/myrepo`, or `.` for current directory
   - Remote URLs: `https://github.com/user/repo.git`, `git@github.com:user/repo.git`
   - Repositories are automatically cloned to `~/.gitutil/repos/` if they don't exist locally
2. **View commit history** - See all commits with hash, author, timestamp, and message
3. **Revert branch to commit** - Safely reset your branch to any previous commit with automatic backup
4. **Cleanup repository** - Delete local repository clones from the workspace
5. **Exit** - Close the application

#### Automatic Backup Branches

**NEW:** GitUtil now automatically creates a backup branch before any rollback operation!

When you revert to an earlier commit, GitUtil creates a backup branch with the format:
```
backup/before-rollback-YYYYMMDD_HHMMSS
```

This backup branch points to the state of your repository **before** the rollback, allowing you to:
- Easily recover if you made a mistake
- Review what was lost during the rollback
- Switch back to the previous state with a simple `git checkout`

#### Automatic Push to Remote

**NEW:** GitUtil now automatically pushes rollback changes to the remote repository!

After successfully reverting to an earlier commit locally, GitUtil will:
- Automatically push the changes to the remote repository using `git push --force-with-lease`
- Ensure the rollback is applied to the main branch on the remote
- Use `--force-with-lease` for safety (prevents overwriting changes you don't know about)

If the push fails (e.g., no remote configured or network issues):
- The local rollback still succeeds
- GitUtil shows a warning with instructions to push manually
- You can complete the push later with: `git push --force-with-lease`

**Example:**
```bash
# Before rollback: You're on commit 5
# GitUtil creates: backup/before-rollback-20260208_193814 (points to commit 5)
# After rollback: You're on commit 2 (both locally AND on remote)

# To recover to the pre-rollback state:
git checkout backup/before-rollback-20260208_193814
# Or create a new branch from it:
git checkout -b recovery backup/before-rollback-20260208_193814
```

The backup is created automatically in all interfaces:
- Terminal UI (`gitutil.sh`)
- Mobile Android App

#### Auto-Clone Functionality

GitUtil can now work with remote repositories without manual cloning:

- **Provide a URL**: Enter any git repository URL when prompted for a repository path
- **Automatic cloning**: If the repository isn't already cloned, it will be cloned automatically
- **Smart caching**: Already cloned repositories are reused, avoiding duplicate clones
- **Default location**: Repositories are cloned to `~/.gitutil/repos/` (customizable via `GITUTIL_REPOS_DIR`)

Example:
```bash
# In the interactive UI, select option 1 and enter:
https://github.com/torvalds/linux.git

# GitUtil will:
# 1. Detect it's a remote URL
# 2. Clone to ~/.gitutil/repos/linux
# 3. Allow you to browse commits and revert branches
```

### Direct Script Usage

You can also call the scripts directly:

```bash
# Prepare a repository (clone if URL, or return local path)
./scripts/prepare_repo.sh /path/to/repo
./scripts/prepare_repo.sh https://github.com/user/repo.git

# Validate a repository
./scripts/validate_repo.sh /path/to/repo

# Fetch commit history
./scripts/fetch_commits.sh /path/to/repo

# Revert to a specific commit
./scripts/revert_branch.sh /path/to/repo <commit-hash>

# Cleanup a repository (delete from disk)
./scripts/cleanup_repo.sh /path/to/repo
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

### For Mobile App (Android)
- Android 7.0 (API 24) or higher
- Storage permission (granted when you first launch the app)
- About 10 MB of storage space
- That's it! No external dependencies required

### For Terminal Interface (Desktop/Server)
- Bash shell (version 4.0 or higher)
- Git command-line tools
- Terminal with color support (recommended)