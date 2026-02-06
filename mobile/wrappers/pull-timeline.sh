#!/bin/bash
LOCATION_PATH="$1"
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    echo "ERROR: Invalid location"
    exit 1
fi
cd "${LOCATION_PATH}" || exit 1
git log --all --pretty=format:'SNAPSHOT_BEGIN%nIDENTIFIER:%H%nCONTRIBUTOR:%an%nWHEN:%at%nTITLE:%s%nDETAILS:%b%nSNAPSHOT_END' --date-order
