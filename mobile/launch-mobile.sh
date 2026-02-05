#!/bin/bash
# GitUtil Mobile Launcher - Termux Edition
# Launches web interface using wrapper scripts

MOBILE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_DIR="${MOBILE_ROOT}/wrappers"
UI_FILE="${MOBILE_ROOT}/touch-ui.html"

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

chmod +x "${WRAPPER_DIR}"/*.sh

echo "✓ Wrappers generated"
echo ""
echo "Opening interface..."
echo "Wrapper location: ${WRAPPER_DIR}"
echo ""

# Check for browser
if command -v termux-open-url &> /dev/null; then
    termux-open-url "file://${UI_FILE}"
elif command -v xdg-open &> /dev/null; then
    xdg-open "${UI_FILE}"
else
    echo "📱 Manual step required:"
    echo "   Open this file in your browser:"
    echo "   ${UI_FILE}"
fi

echo ""
echo "💡 Tip: Bookmark this page for quick access"
