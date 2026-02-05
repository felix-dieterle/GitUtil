#!/bin/bash
# Git commit history extractor
# Usage: ./fetch_commits.sh <repo_path>

REPO_PATH="${1:-.}"

if [ ! -d "$REPO_PATH/.git" ]; then
    echo "ERROR: Not a git repository"
    exit 1
fi

cd "$REPO_PATH" || exit 1

git log --all --pretty=format:'COMMIT_START%nHASH:%H%nAUTHOR:%an%nTIMESTAMP:%at%nSUBJECT:%s%nBODY:%b%nCOMMIT_END' --date-order
