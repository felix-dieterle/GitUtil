#!/bin/bash
# GitUtil Mobile Launcher - Termux Edition
# Launches wrapper bridge server and web interface

MOBILE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_DIR="${MOBILE_ROOT}/wrappers"
UI_FILE="${MOBILE_ROOT}/touch-ui.html"
BRIDGE_SCRIPT="${MOBILE_ROOT}/wrapper-bridge.py"

echo "🚀 GitUtil Mobile - Android Edition"
echo "===================================="

# Create wrapper directory if not exists
mkdir -p "${WRAPPER_DIR}"

# Generate validation wrapper
cat > "${WRAPPER_DIR}/check-location.sh" << 'WRAPPER_END'
#!/bin/bash
LOCATION_PATH="$1"
if [[ -d "${LOCATION_PATH}/.git" ]]; then
    echo "LOCATION_VALID"
    exit 0
else
    echo "LOCATION_INVALID"
    exit 1
fi
WRAPPER_END

# Generate timeline wrapper  
cat > "${WRAPPER_DIR}/pull-timeline.sh" << 'WRAPPER_END'
#!/bin/bash
LOCATION_PATH="$1"
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    echo "ERROR: Invalid location"
    exit 1
fi
cd "${LOCATION_PATH}" || exit 1
git log --all --pretty=format:'SNAPSHOT_BEGIN%nIDENTIFIER:%H%nCONTRIBUTOR:%an%nWHEN:%at%nTITLE:%s%nDETAILS:%b%nSNAPSHOT_END' --date-order
WRAPPER_END

# Generate rollback wrapper
cat > "${WRAPPER_DIR}/apply-rollback.sh" << 'WRAPPER_END'
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
WRAPPER_END

# Generate workspace wrapper
cat > "${WRAPPER_DIR}/ensure-workspace.sh" << 'WRAPPER_END'
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
WRAPPER_END

# Generate list repositories wrapper
cat > "${WRAPPER_DIR}/list-repositories.sh" << 'WRAPPER_END'
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
WRAPPER_END

# Generate clone repository wrapper
cat > "${WRAPPER_DIR}/clone-repository.sh" << 'WRAPPER_END'
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
WRAPPER_END

# Generate get default workspace wrapper
cat > "${WRAPPER_DIR}/get-default-workspace.sh" << 'WRAPPER_END'
#!/bin/bash
echo "/sdcard/GitUtil/repos"
exit 0
WRAPPER_END

chmod +x "${WRAPPER_DIR}"/*.sh

echo "✓ Wrappers generated"
echo ""

# Start the bridge server
if command -v python3 &> /dev/null; then
    echo "Starting wrapper bridge server..."
    python3 "${BRIDGE_SCRIPT}" &
    BRIDGE_PID=$!
    echo "✓ Bridge server running (PID: ${BRIDGE_PID})"
    sleep 2
    
    # Save PID for later cleanup
    echo "${BRIDGE_PID}" > "${MOBILE_ROOT}/.bridge.pid"
    
    echo ""
    echo "📱 Opening mobile interface..."
    echo ""
    
    # Check for browser
    if command -v termux-open-url &> /dev/null; then
        termux-open-url "http://localhost:8765"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:8765"
    else
        echo "📱 Manual step required:"
        echo "   Open this URL in your browser:"
        echo "   http://localhost:8765"
    fi
    
    echo ""
    echo "💡 Tip: Keep this terminal open while using the interface"
    echo "   Press Ctrl+C to stop the server"
    echo ""
    
    # Wait for interrupt
    trap "kill ${BRIDGE_PID} 2>/dev/null; rm -f ${MOBILE_ROOT}/.bridge.pid; echo ''; echo 'Server stopped.'; exit 0" INT TERM
    wait ${BRIDGE_PID}
else
    echo "❌ Python 3 not found"
    echo "   Install with: pkg install python"
    echo ""
    echo "📱 Fallback: Open this file directly in your browser:"
    echo "   ${UI_FILE}"
    echo "   (Note: You'll need to run the bridge server separately)"
fi

