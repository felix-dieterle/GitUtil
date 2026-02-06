#!/bin/bash
LOCATION_PATH="$1"
if [[ -d "${LOCATION_PATH}/.git" ]]; then
    echo "LOCATION_VALID"
    exit 0
else
    echo "LOCATION_INVALID"
    exit 1
fi
