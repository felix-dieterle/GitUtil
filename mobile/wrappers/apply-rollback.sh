#!/bin/bash
LOCATION_PATH="$1"
TARGET_HASH="$2"
if [[ -z "${LOCATION_PATH}" || -z "${TARGET_HASH}" ]]; then
    echo "ERROR: Missing parameters"
    exit 1
fi
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    echo "ERROR: Invalid repository location"
    exit 1
fi
cd "${LOCATION_PATH}" || exit 1
echo "Rolling back to: ${TARGET_HASH}"
if ! git rev-parse --verify "${TARGET_HASH}" >/dev/null 2>&1; then
    echo "ROLLBACK_FAILED"
    echo "ERROR: Commit ${TARGET_HASH} not found in repository"
    exit 1
fi
git reset --hard "${TARGET_HASH}" 2>&1
if [[ $? -eq 0 ]]; then
    echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
    exit 0
else
    echo "ROLLBACK_FAILED"
    echo "ERROR: git reset command failed"
    exit 1
fi
