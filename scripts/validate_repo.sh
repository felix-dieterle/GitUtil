#!/bin/bash
# Validate git repository
# Usage: ./validate_repo.sh <repo_path>

REPO_PATH="${1:-.}"

if [ -d "$REPO_PATH/.git" ]; then
    echo "VALID"
    exit 0
else
    echo "INVALID"
    exit 1
fi
