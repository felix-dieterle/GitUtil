# GitUtil Android App Architecture

## Overview
This document describes a shell-script-based Android application for git branch management.

## Architecture Pattern: Shell-Wrapper Design

Instead of using JGit or other Java git libraries, this app uses a unique architecture where core git operations are performed via shell scripts, and the Android UI acts as a graphical wrapper.

### Components

1. **Shell Scripts Layer** (`scripts/`)
   - `fetch_commits.sh` - Extracts commit history with custom format
   - `revert_branch.sh` - Performs hard reset to specified commit
   - `validate_repo.sh` - Checks if path contains valid git repo

2. **Android Wrapper Layer** (`android-shell/`)
   - Minimal Activities that execute shell scripts via Runtime.exec()
   - Parse script output and display in UI
   - No traditional git libraries needed

3. **Data Flow**
   ```
   User Input (Android UI) 
      → Execute Shell Script (Runtime.exec)
      → Parse Output (Custom parser)
      → Display Results (ListView/RecyclerView)
      → User Selection
      → Execute Revert Script
      → Show Confirmation
   ```

### Key Differentiators

- **No Git Libraries**: Uses native git command via shell
- **Script-Based**: Core logic in bash scripts, not Java/Kotlin
- **Minimal Dependencies**: Only Android SDK required
- **Parse-and-Display Pattern**: Scripts output custom format, Android parses

### Implementation Notes

The Android code should:
- Use `ProcessBuilder` or `Runtime.exec()` to run scripts
- Parse multi-line output with custom delimiters (COMMIT_START/COMMIT_END)
- Display in programmatically-created UI (no XML layouts initially)
- Handle async execution with simple Thread + runOnUiThread pattern

### Security Considerations

- Validate all user input before passing to scripts
- Escape special characters in file paths
- Run with limited permissions
- Warn users about hard reset dangers
