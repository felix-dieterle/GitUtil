# GitUtil - Git Branch Rewind Tool

[![Test Suite](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml/badge.svg)](https://github.com/felix-dieterle/GitUtil/actions/workflows/test.yml)

An Android application for visually navigating git commit history and reverting branches to previous states.

**Now with an interactive terminal UI!** Use `./gitutil.sh` to access all features through a user-friendly command-line interface.

## Features

- **Interactive Terminal UI** - User-friendly menu-based interface for all git operations
- Browse git repositories on device
- View commit timeline with full details (hash, author, timestamp, message)
- Revert branch to any historical commit with one tap (or menu selection)
- Simple, intuitive interface with color-coded feedback
- Safe operations with confirmation prompts for destructive actions

## Project Structure

This app uses a custom lightweight architecture:
- `gitutil.sh` - Interactive terminal UI (main user interface)
- `scripts/` - Shell scripts for core git operations
  - `validate_repo.sh` - Validates git repositories
  - `fetch_commits.sh` - Extracts commit history
  - `revert_branch.sh` - Reverts branch to specific commit
- `tests/` - Comprehensive test suite for all scripts
- `docs/` - Architecture and integration documentation

## Building

Standard Android build process applies. See build configuration files for dependencies.

## Usage

### Interactive Terminal UI (Recommended)

The easiest way to use GitUtil is through the interactive terminal interface:

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

### Android App (Coming Soon)

1. Launch app
2. Select or enter git repository path
3. Browse commit timeline (newest to oldest)
4. Tap any commit to see details
5. Confirm revert action to reset branch

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

- Android 8.0 (API 26) or higher
- Git repositories must be accessible on device storage
- Bash shell for running scripts and tests