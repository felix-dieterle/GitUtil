#!/bin/bash
# Git branch revert tool
# Usage: ./revert_branch.sh <repo_path> <commit_hash>

REPO_PATH="$1"
COMMIT_HASH="$2"

if [ -z "$REPO_PATH" ] || [ -z "$COMMIT_HASH" ]; then
    echo "ERROR: Missing arguments"
    echo "Usage: $0 <repo_path> <commit_hash>"
    exit 1
fi

if [ ! -d "$REPO_PATH/.git" ]; then
    echo "ERROR: Not a git repository: $REPO_PATH"
    exit 1
fi

cd "$REPO_PATH" || exit 1

echo "Reverting branch to commit: $COMMIT_HASH"
git reset --hard "$COMMIT_HASH"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Branch reverted to $COMMIT_HASH"
    exit 0
else
    echo "ERROR: Failed to revert branch"
    exit 1
fi
