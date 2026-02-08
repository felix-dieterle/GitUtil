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

# Create backup branch with timestamp before rollback
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)
if [ -n "$CURRENT_HEAD" ]; then
    BACKUP_BRANCH="backup/before-rollback-${TIMESTAMP}"
    echo "Creating backup branch: $BACKUP_BRANCH"
    git branch "$BACKUP_BRANCH" "$CURRENT_HEAD" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Backup branch created successfully"
    else
        echo "WARNING: Failed to create backup branch, proceeding with rollback"
    fi
fi

echo "Reverting branch to commit: $COMMIT_HASH"
git reset --hard "$COMMIT_HASH"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to revert branch"
    exit 1
fi

# Push the changes to remote
echo "Pushing changes to remote..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push --force-with-lease origin "$CURRENT_BRANCH"

if [ $? -eq 0 ]; then
    echo "SUCCESS: Branch reverted to $COMMIT_HASH and pushed to remote"
    exit 0
else
    echo "WARNING: Branch reverted locally to $COMMIT_HASH, but push to remote failed"
    echo "You may need to push manually with: git push --force-with-lease"
    exit 0
fi
