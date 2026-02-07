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

echo "[WRAPPER] ========================================"
echo "[WRAPPER] Apply Rollback Wrapper Started"
echo "[WRAPPER] ========================================"
echo "[WRAPPER] Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "[WRAPPER] Repository Path: ${LOCATION_PATH}"
echo "[WRAPPER] Target Commit: ${TARGET_HASH}"

if [[ -z "${LOCATION_PATH}" || -z "${TARGET_HASH}" ]]; then
    echo "[WRAPPER] ERROR: Missing required parameters"
    echo "ERROR: Missing parameters (path or commit hash)"
    exit 1
fi

echo "[WRAPPER] Validating repository location..."
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    echo "[WRAPPER] ERROR: Repository validation failed"
    echo "[WRAPPER] Path does not contain a .git directory"
    echo "ERROR: Invalid repository location: ${LOCATION_PATH}"
    exit 1
fi
echo "[WRAPPER] ✓ Repository location is valid"

echo "[WRAPPER] Changing to repository directory..."
cd "${LOCATION_PATH}" || {
    echo "[WRAPPER] ERROR: Failed to change directory"
    echo "ERROR: Could not access repository directory"
    exit 1
}
echo "[WRAPPER] ✓ Working directory: $(pwd)"

echo "[WRAPPER] Verifying commit exists in repository..."
if ! git rev-parse --verify "${TARGET_HASH}" >/dev/null 2>&1; then
    echo "[WRAPPER] ERROR: Commit verification failed"
    echo "[WRAPPER] Commit ${TARGET_HASH} not found in this repository"
    echo "ROLLBACK_FAILED"
    echo "ERROR: Commit ${TARGET_HASH} not found in repository"
    exit 1
fi
echo "[WRAPPER] ✓ Commit ${TARGET_HASH} verified"

echo "[WRAPPER] Getting current HEAD for reference..."
current_head=$(git rev-parse HEAD 2>&1)
echo "[WRAPPER] Current HEAD: ${current_head}"

echo "[WRAPPER] Executing git reset --hard ${TARGET_HASH}..."
output=$(git reset --hard "${TARGET_HASH}" 2>&1)
exit_code=$?

echo "[WRAPPER] Git reset exit code: ${exit_code}"
echo "[WRAPPER] Git reset output: ${output}"

if [[ ${exit_code} -eq 0 ]]; then
    new_head=$(git rev-parse HEAD 2>&1)
    echo "[WRAPPER] ✓ Rollback successful"
    echo "[WRAPPER] Previous HEAD: ${current_head}"
    echo "[WRAPPER] New HEAD: ${new_head}"
    echo "[WRAPPER] ========================================"
    echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
    exit 0
else
    echo "[WRAPPER] ❌ Rollback failed"
    echo "[WRAPPER] Git error output: ${output}"
    echo "[WRAPPER] ========================================"
    echo "ROLLBACK_FAILED"
    echo "ERROR: git reset command failed: ${output}"
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

# Generate list GitHub repos wrapper
cat > "${WRAPPER_DIR}/list-github-repos.sh" << 'WRAPPER_END'
#!/bin/bash
GITHUB_TOKEN="$1"
if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo "ERROR: GitHub token required"
    exit 1
fi

# Use curl to fetch GitHub repositories
RESPONSE=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user/repos?per_page=100&sort=updated")

# Check if authentication failed
if echo "${RESPONSE}" | grep -q '"message": "Bad credentials"'; then
    echo "ERROR: Invalid GitHub token"
    exit 1
fi

echo "GITHUB_REPOS_BEGIN"

# Parse JSON response and output in expected format
echo "${RESPONSE}" | python3 -c "
import sys, json
try:
    repos = json.load(sys.stdin)
    for repo in repos:
        print('GITHUB_REPO_NAME:' + repo['name'])
        print('GITHUB_REPO_FULLNAME:' + repo['full_name'])
        print('GITHUB_REPO_URL:' + repo['clone_url'])
        print('GITHUB_REPO_DESC:' + repo.get('description', ''))
        print('GITHUB_REPO_PRIVATE:' + str(repo['private']).lower())
        print('GITHUB_REPO_SEPARATOR')
except Exception as e:
    print(f'ERROR: Failed to parse response: {e}', file=sys.stderr)
    sys.exit(1)
"

echo "GITHUB_REPOS_END"
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

