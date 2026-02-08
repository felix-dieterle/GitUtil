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

# Step tracking functions
report_step() {
    echo "STEP_STATUS:$1:$2"  # Format: STEP_STATUS:<step_name>:<status>
}

report_step_detail() {
    echo "STEP_DETAIL:$1"  # Format: STEP_DETAIL:<message>
}

# Rollback function to restore state on failure
rollback_changes() {
    local backup_branch="$1"
    local original_head="$2"
    
    report_step_detail "Transaction failed - initiating rollback"
    
    if [[ -n "$backup_branch" ]] && git rev-parse --verify "$backup_branch" >/dev/null 2>&1; then
        report_step_detail "Restoring from backup branch: $backup_branch"
        git reset --hard "$backup_branch" 2>/dev/null
        git branch -D "$backup_branch" 2>/dev/null
        report_step_detail "State restored to original HEAD: $original_head"
    fi
}

echo "[WRAPPER] ========================================"
echo "[WRAPPER] Apply Rollback Wrapper Started"
echo "[WRAPPER] ========================================"
echo "[WRAPPER] Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "[WRAPPER] Repository Path: ${LOCATION_PATH}"
echo "[WRAPPER] Target Commit: ${TARGET_HASH}"

if [[ -z "${LOCATION_PATH}" || -z "${TARGET_HASH}" ]]; then
    echo "[WRAPPER] ERROR: Missing required parameters"
    echo "ERROR: Missing parameters (path or commit hash)"
    exit 1
fi

# Step 1: Validate repository
report_step "validate" "in_progress"
echo "[WRAPPER] Validating repository location..."
if [[ ! -d "${LOCATION_PATH}/.git" ]]; then
    report_step "validate" "failed"
    echo "[WRAPPER] ERROR: Repository validation failed"
    echo "[WRAPPER] Path does not contain a .git directory"
    echo "ERROR: Invalid repository location: ${LOCATION_PATH}"
    exit 1
fi

echo "[WRAPPER] Changing to repository directory..."
cd "${LOCATION_PATH}" || {
    report_step "validate" "failed"
    echo "[WRAPPER] ERROR: Failed to change directory"
    echo "ERROR: Could not access repository directory"
    exit 1
}
echo "[WRAPPER] ✓ Working directory: $(pwd)"

echo "[WRAPPER] Verifying commit exists in repository..."
if ! git rev-parse --verify "${TARGET_HASH}" >/dev/null 2>&1; then
    report_step "validate" "failed"
    echo "[WRAPPER] ERROR: Commit verification failed"
    echo "[WRAPPER] Commit ${TARGET_HASH} not found in this repository"
    echo "ROLLBACK_FAILED"
    echo "ERROR: Commit ${TARGET_HASH} not found in repository"
    exit 1
fi
echo "[WRAPPER] ✓ Commit ${TARGET_HASH} verified"
report_step "validate" "completed"

# Step 2: Create backup branch
report_step "backup" "in_progress"
echo "[WRAPPER] Getting current HEAD for reference..."
current_head=$(git rev-parse HEAD 2>&1)
echo "[WRAPPER] Current HEAD: ${current_head}"

echo "[WRAPPER] Creating backup branch before rollback..."
timestamp=$(date +%Y%m%d_%H%M%S_%N | cut -c1-21)  # Include nanoseconds for uniqueness
backup_branch="backup/before-rollback-${timestamp}"
echo "[WRAPPER] Backup branch name: ${backup_branch}"
git branch "${backup_branch}" "${current_head}" 2>/dev/null
if [[ $? -eq 0 ]]; then
    echo "[WRAPPER] ✓ Backup branch created successfully: ${backup_branch}"
    report_step "backup" "completed"
else
    report_step "backup" "failed"
    echo "[WRAPPER] ❌ Failed to create backup branch"
    echo "ERROR: Failed to create backup branch"
    exit 1
fi

# Step 3: Reset to target commit
report_step "reset" "in_progress"
echo "[WRAPPER] Executing git reset --hard ${TARGET_HASH}..."
output=$(git reset --hard "${TARGET_HASH}" 2>&1)
exit_code=$?

echo "[WRAPPER] Git reset exit code: ${exit_code}"
echo "[WRAPPER] Git reset output: ${output}"

if [[ ${exit_code} -ne 0 ]]; then
    report_step "reset" "failed"
    echo "[WRAPPER] ❌ Rollback failed"
    echo "[WRAPPER] Git error output: ${output}"
    # Rollback the transaction
    rollback_changes "${backup_branch}" "${current_head}"
    echo "[WRAPPER] ========================================"
    echo "ROLLBACK_FAILED"
    echo "ERROR: git reset command failed - changes rolled back"
    exit 1
fi

new_head=$(git rev-parse HEAD 2>&1)
echo "[WRAPPER] ✓ Reset successful"
echo "[WRAPPER] Previous HEAD: ${current_head}"
echo "[WRAPPER] New HEAD: ${new_head}"
report_step "reset" "completed"

# Step 4: Push to remote
report_step "push" "in_progress"
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "[WRAPPER] Pushing to remote branch: ${current_branch}"

# Check if remote exists
if git remote | grep -q "^origin$"; then
    git push --force-with-lease origin "${current_branch}" 2>/dev/null
    push_exit=$?

    if [[ ${push_exit} -eq 0 ]]; then
        report_step "push" "completed"
        echo "[WRAPPER] ✓ Successfully pushed to remote"
        # Keep backup branch for user reference (not deleted on success)
        echo "[WRAPPER] ========================================"
        echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
        exit 0
    else
        report_step "push" "failed"
        echo "[WRAPPER] ❌ Push to remote failed"
        # Rollback the transaction
        rollback_changes "${backup_branch}" "${current_head}"
        echo "[WRAPPER] ========================================"
        echo "ROLLBACK_FAILED"
        echo "ERROR: Push to remote failed - changes rolled back to maintain consistency"
        exit 1
    fi
else
    # No remote configured - skip push and succeed
    report_step "push" "completed"
    report_step_detail "No remote configured - push skipped"
    echo "[WRAPPER] ℹ No remote configured - push skipped"
    # Keep backup branch for user reference (not deleted on success)
    echo "[WRAPPER] ========================================"
    echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
    exit 0
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

# Generate cleanup repository wrapper
cat > "${WRAPPER_DIR}/cleanup-repository.sh" << 'WRAPPER_END'
#!/bin/bash
REPO_PATH="$1"

if [[ -z "${REPO_PATH}" ]]; then
    echo "ERROR: Repository path required"
    exit 1
fi

# Check if directory exists
if [[ ! -d "${REPO_PATH}" ]]; then
    echo "ERROR: Directory does not exist: ${REPO_PATH}"
    exit 1
fi

# Verify it's a git repository
if [[ ! -d "${REPO_PATH}/.git" ]]; then
    echo "ERROR: Not a git repository: ${REPO_PATH}"
    exit 1
fi

# Delete the repository
rm -rf "${REPO_PATH}"
if [[ $? -eq 0 ]]; then
    echo "CLEANUP_SUCCESS"
    exit 0
else
    echo "CLEANUP_FAILED"
    echo "ERROR: Failed to delete repository"
    exit 1
fi
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

