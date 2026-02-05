# GitUtil Interactive UI - Quick Start Guide

## Installation

No installation required! GitUtil is a standalone shell script.

## Quick Start

### Basic Usage

```bash
# Launch the interactive UI
./gitutil.sh

# Or specify a repository path
./gitutil.sh /path/to/your/repo
```

### Example Session

```
═══════════════════════════════════════════════════════════
GitUtil - Git Branch Rewind Tool
═══════════════════════════════════════════════════════════

Main Menu:
  1) Select repository
  2) View commit history
  3) Revert branch to commit
  4) Exit

Choose an option [1-4]: 2

Commit History:

[1] c0d84f2e
    Author: John Doe
    Date:   2026-02-05 20:10:02
    Msg:    Add new feature

[2] bb4c6fba
    Author: John Doe
    Date:   2026-02-05 19:45:21
    Msg:    Fix bug in parser

[3] a1b2c3d4
    Author: Jane Smith
    Date:   2026-02-05 18:30:15
    Msg:    Initial commit

✓ Total commits: 3
```

## Features

### 1. Select Repository
- Browse to any git repository on your system
- Automatic validation ensures the path is a valid git repository
- Supports relative and absolute paths

### 2. View Commit History
- See all commits with full details
- Commits numbered for easy reference
- Newest commits first

### 3. Revert Branch to Commit
- Select any commit by its number
- Clear warning about destructive operation
- Confirmation prompt before reverting
- Safe cancellation option (enter 0 or "no")

### 4. Exit
- Clean exit with goodbye message

## Color Coding

- **Green (✓)**: Success messages, valid operations
- **Red (✗)**: Error messages, failed operations
- **Yellow (⚠)**: Warnings, important notices
- **Cyan (ℹ)**: Informational messages, progress indicators

## Safety Features

### Confirmation Prompts
Before reverting a branch, you'll see:
```
⚠ This will reset the current branch to the selected commit.
⚠ All commits after this point will be lost from the current branch.

Selected commit:
  bb4c6fba - Fix bug in parser

Are you sure you want to continue? (yes/no):
```

You must type "yes" exactly to proceed. Any other input cancels the operation.

### Cancel Anytime
- Option 0 in commit selection cancels the revert
- Typing anything other than "yes" cancels destructive operations
- Option 4 in main menu exits cleanly

## Tips

1. **First Time Use**: Start with option 2 (View commit history) to familiarize yourself with your repository
2. **Before Reverting**: Always note the current HEAD commit in case you need to return to it
3. **Test First**: Try the tool on a test repository before using it on important projects
4. **Backup**: Consider creating a backup branch before reverting: `git branch backup`

## Troubleshooting

### "Invalid git repository"
- Make sure the path points to a directory with a `.git` folder
- Check that you have permissions to access the repository

### "Failed to fetch commits"
- Ensure the repository has at least one commit
- Verify git is installed and working: `git --version`

### Script Not Executable
```bash
chmod +x gitutil.sh
```

## Advanced Usage

### Using with Different Branches
GitUtil operates on your current branch. To revert a different branch:
```bash
cd /path/to/repo
git checkout branch-name
/path/to/gitutil.sh .
```

### Integration with Other Tools
The UI uses standard input/output, so it can be integrated into larger workflows:
```bash
# Launch with specific repo
./gitutil.sh ~/projects/my-repo
```

## Requirements

- Bash 4.0 or higher
- Git installed and in PATH
- Terminal with ANSI color support (most modern terminals)

## Support

For issues or questions, please check:
- Test suite: `./tests/run_tests.sh`
- Project README: `README.md`
- GitHub repository
