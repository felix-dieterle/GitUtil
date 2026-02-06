#!/bin/bash
LOCATION_PATH="$1"
TARGET_HASH="$2"
if [[ -z "${LOCATION_PATH}" || -z "${TARGET_HASH}" ]]; then
    echo "ERROR: Missing parameters"
    exit 1
fi
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    echo "ERROR: Invalid location"
    exit 1
fi
cd "${LOCATION_PATH}" || exit 1
echo "Rolling back to: ${TARGET_HASH}"
git reset --hard "${TARGET_HASH}"
if [[ $? -eq 0 ]]; then
    echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
    exit 0
else
    echo "ROLLBACK_FAILED"
    exit 1
fi
