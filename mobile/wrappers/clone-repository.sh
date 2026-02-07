#!/bin/bash
REPO_URL="$1"
REPO_NAME="$2"
DEFAULT_WORKSPACE="/sdcard/GitUtil/repos"

if [[ -z "${REPO_URL}" ]]; then
    echo "ERROR: Repository URL required"
    exit 1
fi

# Extract repo name from URL if not provided
if [[ -z "${REPO_NAME}" ]]; then
    REPO_NAME=$(basename "${REPO_URL}" .git)
    REPO_NAME="${REPO_NAME//[^a-zA-Z0-9._-]/_}"
fi

# Ensure workspace exists
mkdir -p "${DEFAULT_WORKSPACE}"

TARGET_DIR="${DEFAULT_WORKSPACE}/${REPO_NAME}"
if [[ -d "${TARGET_DIR}" ]]; then
    echo "CLONE_FAILED"
    echo "ERROR: Directory already exists: ${REPO_NAME}"
    exit 1
fi

# Clone the repository
git clone "${REPO_URL}" "${TARGET_DIR}"
if [[ $? -eq 0 ]]; then
    echo "CLONE_SUCCESS:${TARGET_DIR}"
    exit 0
else
    echo "CLONE_FAILED"
    echo "ERROR: Git clone failed"
    exit 1
fi
