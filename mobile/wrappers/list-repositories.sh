#!/bin/bash
WORKSPACE_PATH="${1:-/sdcard/GitUtil/repos}"
echo "REPOS_BEGIN"
if [[ -d "${WORKSPACE_PATH}" ]]; then
    for dir in "${WORKSPACE_PATH}"/*; do
        if [[ -d "${dir}/.git" ]]; then
            basename="${dir##*/}"
            echo "REPO_NAME:${basename}"
            echo "REPO_PATH:${dir}"
            echo "REPO_SEPARATOR"
        fi
    done
fi
echo "REPOS_END"
exit 0
