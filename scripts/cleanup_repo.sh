#!/bin/bash
# Repository cleanup tool - deletes local repository clones from workspace
# Usage: ./cleanup_repo.sh <repo_path>

REPO_PATH="$1"

if [ -z "$REPO_PATH" ]; then
    echo "ERROR: Repository path required"
    echo "Usage: $0 <repo_path>"
    exit 1
fi

# Expand tilde if present
REPO_PATH="${REPO_PATH/#\~/$HOME}"

# Convert to absolute path if it exists
if [ -d "$REPO_PATH" ]; then
    REPO_PATH="$(cd "$REPO_PATH" && pwd)"
fi

# Check if directory exists
if [ ! -d "$REPO_PATH" ]; then
    echo "ERROR: Directory does not exist: $REPO_PATH"
    exit 1
fi

# Verify it's a git repository
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "ERROR: Not a git repository: $REPO_PATH"
    exit 1
fi

# Delete the repository
if rm -rf "$REPO_PATH"; then
    echo "SUCCESS: Repository deleted: $REPO_PATH"
    exit 0
else
    echo "ERROR: Failed to delete repository: $REPO_PATH"
    exit 1
fi
