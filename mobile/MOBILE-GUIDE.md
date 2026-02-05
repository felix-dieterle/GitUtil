# GitUtil Mobile - Quick Start Guide

## What is GitUtil Mobile?

GitUtil Mobile is a touch-optimized web interface for managing git repositories on Android devices. It lets you browse commit history and rollback branches using a mobile-friendly interface that runs directly in Termux.

## Prerequisites

1. **Install Termux** from F-Droid (not Google Play - that version is deprecated)
   - Download: https://f-droid.org/en/packages/com.termux/

2. **Install required packages** in Termux:
   ```bash
   pkg update
   pkg install git bash python
   ```

3. **Grant storage permission** (if needed):
   ```bash
   termux-setup-storage
   ```

## Installation

1. **Download GitUtil Mobile** package from the releases page

2. **Extract the package:**
   ```bash
   cd ~/storage/downloads  # or wherever you downloaded it
   unzip gitutil-mobile-*.zip
   cd gitutil-mobile-*
   ```

3. **Launch the interface:**
   ```bash
   bash mobile/launch-mobile.sh
   ```

The launcher will:
- Create wrapper scripts automatically
- Start the Python bridge server (localhost:8765)
- Open the interface in your browser
- Keep running until you press Ctrl+C

**Important:** Keep the terminal open while using the interface. The bridge server must be running for the UI to execute git operations.

## Using the Interface

### First Time Setup

1. The interface will open in your browser
2. You'll see the "Repository Location" screen
3. Enter the full path to your git repository
   - Example: `/storage/emulated/0/repos/my-project`
   - Or: `~/storage/shared/git/my-repo`

4. Tap "Verify Location" to validate the repository

### Browsing Commits

Once validated, you'll see:
- Your repository path at the top
- A scrollable list of commit snapshots
- Each snapshot shows:
  - Short hash (8 characters)
  - Commit message
  - Author name
  - Timestamp

### Rolling Back to a Snapshot

1. **Tap on any snapshot** to select it
   - The selected snapshot will be highlighted
   - The "Apply Rollback" button will activate

2. **Tap "Apply Rollback"**
   - A confirmation dialog will appear
   - Warning: This will perform a hard reset
   - All uncommitted changes will be lost

3. **Confirm the operation**
   - The branch will be reset to the selected snapshot
   - You'll see a success message
   - The timeline will refresh

### Switching Repositories

- Tap "Change Location" to switch to a different repository
- Your last repository path is remembered automatically

## Tips & Tricks

### Access URL
After the first launch, you can access the interface at:
```
http://localhost:8765
```

Make sure the bridge server is running (via `launch-mobile.sh`) before opening this URL.

### Stopping the Server
Press Ctrl+C in the terminal where you ran `launch-mobile.sh` to stop the bridge server.

### Finding Repository Paths

To find the path of a git repository in Termux:
```bash
cd /path/to/your/repo
pwd
```

Common locations:
- `~/storage/shared/` - Your device's internal storage
- `~/storage/downloads/` - Downloads folder
- `~/repos/` - If you clone repos in Termux home

### Verifying the Repository

Before using GitUtil Mobile, make sure your repository is valid:
```bash
cd /path/to/repo
git status
```

If this works, GitUtil Mobile will work too.

### Working with Remote Repositories

GitUtil Mobile works with any git repository, including ones with remotes:

```bash
# Clone a repository
cd ~/storage/shared/
git clone https://github.com/user/repo.git

# Use the path in GitUtil Mobile
# Path: /storage/emulated/0/shared/repo
```

## Troubleshooting

### "Invalid repository location" error
- Double-check the path is correct (use `pwd` in the repo directory)
- Make sure the directory contains a `.git` folder
- Verify git is installed: `which git`
- Ensure the bridge server is running

### Interface doesn't load
- Check that the bridge server is running
- Verify Python 3 is installed: `python3 --version`
- Try accessing http://localhost:8765 directly
- Check for port conflicts (another service using 8765)

### Wrapper execution fails
- Make sure the bridge server is running
- Check that wrappers exist in `mobile/wrappers/`
- Verify wrapper permissions: `ls -la mobile/wrappers/`
- Check server output for error messages

### Browser compatibility
- The interface works with any modern Android browser
- Tested with: Chrome, Firefox, Brave, Samsung Internet
- If one browser has issues, try another

## Advanced Usage

### Custom Wrapper Location

The launcher creates wrappers in `mobile/wrappers/`. If you need them elsewhere:

```bash
export WRAPPER_DIR="/custom/path"
bash mobile/launch-mobile.sh
```

### Integrating with Other Tools

The mobile interface uses three wrapper scripts:
- `check-location.sh` - Validates repositories
- `pull-timeline.sh` - Fetches commit history
- `apply-rollback.sh` - Performs rollbacks

You can call these directly from other scripts if needed.

### Running on Desktop Linux

While designed for Android, GitUtil Mobile works on any Linux system:

```bash
bash mobile/launch-mobile.sh
# Opens in your default browser
```

## Safety Notes

### Before Rolling Back

- **Uncommitted changes will be lost** - Commit or stash them first
- **Consider creating a branch** - `git branch backup-$(date +%s)`
- **Check for unpushed commits** - `git log origin/main..HEAD`

### Recovery Options

If you rollback by mistake:
1. Check `git reflog` to see the previous HEAD position
2. Use `git reset --hard <previous-hash>` to undo the rollback
3. The reflog keeps history for 30-90 days by default

## Getting Help

- Check the main README.md for full documentation
- Run the test suite to verify your installation: `./tests/run_tests.sh`
- Report issues on the GitHub repository

## What's Next?

- Explore the terminal interface: `./gitutil.sh`
- Read the architecture docs in `docs/`
- Contribute improvements via pull requests

---

**GitUtil Mobile** - Making git repository management touch-friendly for Android developers.
