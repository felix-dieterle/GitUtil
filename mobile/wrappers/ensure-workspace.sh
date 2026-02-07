#!/bin/bash
DEFAULT_WORKSPACE="/sdcard/GitUtil/repos"
if [[ ! -d "${DEFAULT_WORKSPACE}" ]]; then
    mkdir -p "${DEFAULT_WORKSPACE}"
    if [[ $? -eq 0 ]]; then
        echo "WORKSPACE_CREATED:${DEFAULT_WORKSPACE}"
        exit 0
    else
        echo "ERROR: Failed to create workspace"
        exit 1
    fi
fi
echo "WORKSPACE_EXISTS:${DEFAULT_WORKSPACE}"
exit 0
