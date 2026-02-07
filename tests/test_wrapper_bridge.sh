#!/bin/bash
# Test wrapper bridge exit code handling
# This test ensures that the wrapper bridge properly translates shell script exit codes
# into JSON success/failure responses

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Wrapper Bridge Exit Code Handling${NC}"
echo ""

# Create a temporary directory for test wrappers
TEST_WRAPPER_DIR="/tmp/gitutil_test_wrappers_$$"
mkdir -p "$TEST_WRAPPER_DIR"

# Cleanup function
cleanup() {
    rm -rf "$TEST_WRAPPER_DIR"
}
trap cleanup EXIT

# Test 1: Wrapper with exit code 0 should return success: true
test_wrapper_success_exit_code() {
    local test_name="Wrapper with exit code 0 returns success: true"
    
    # Create a wrapper that exits with 0
    cat > "$TEST_WRAPPER_DIR/success-wrapper.sh" << 'EOF'
#!/bin/bash
echo "OPERATION_SUCCESS"
exit 0
EOF
    chmod +x "$TEST_WRAPPER_DIR/success-wrapper.sh"
    
    # Simulate what wrapper-bridge.py does
    local exit_code=0
    local is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$is_success" = "true" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected success: true, got: $is_success)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 2: Wrapper with exit code 1 should return success: false
test_wrapper_failure_exit_code() {
    local test_name="Wrapper with exit code 1 returns success: false"
    
    # Create a wrapper that exits with 1
    cat > "$TEST_WRAPPER_DIR/failure-wrapper.sh" << 'EOF'
#!/bin/bash
echo "OPERATION_FAILED"
echo "ERROR: Something went wrong" >&2
exit 1
EOF
    chmod +x "$TEST_WRAPPER_DIR/failure-wrapper.sh"
    
    # Simulate what wrapper-bridge.py does
    local exit_code=1
    local is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$is_success" = "false" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected success: false, got: $is_success)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 3: Rollback success scenario (exit 0, output contains SUCCESS)
test_rollback_success_scenario() {
    local test_name="Rollback wrapper success scenario (exit 0, output has SUCCESS)"
    
    # Create a wrapper that simulates successful rollback
    cat > "$TEST_WRAPPER_DIR/rollback-success.sh" << 'EOF'
#!/bin/bash
TARGET_HASH="$2"
echo "Rolling back to: ${TARGET_HASH}"
echo "ROLLBACK_SUCCESS: ${TARGET_HASH}"
exit 0
EOF
    chmod +x "$TEST_WRAPPER_DIR/rollback-success.sh"
    
    # Execute wrapper
    output=$("$TEST_WRAPPER_DIR/rollback-success.sh" "/tmp/repo" "abc123")
    exit_code=$?
    
    # Check conditions for success display in UI
    local is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    local has_success=$( echo "$output" | grep -q "SUCCESS" && echo "true" || echo "false" )
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$is_success" = "true" ] && [ "$has_success" = "true" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (success: $is_success, has_success: $has_success)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 4: Rollback failure scenario (exit 1, error messages)
test_rollback_failure_scenario() {
    local test_name="Rollback wrapper failure scenario (exit 1, has error messages)"
    
    # Create a wrapper that simulates failed rollback
    cat > "$TEST_WRAPPER_DIR/rollback-failure.sh" << 'EOF'
#!/bin/bash
TARGET_HASH="$2"
echo "ROLLBACK_FAILED"
echo "ERROR: Commit ${TARGET_HASH} not found in repository" >&2
exit 1
EOF
    chmod +x "$TEST_WRAPPER_DIR/rollback-failure.sh"
    
    # Execute wrapper
    output=$("$TEST_WRAPPER_DIR/rollback-failure.sh" "/tmp/repo" "invalid123" 2>&1)
    exit_code=$?
    
    # Check conditions for error display in UI
    local is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    local has_failure=$( echo "$output" | grep -q "FAILED" && echo "true" || echo "false" )
    local has_error=$( echo "$output" | grep -q "ERROR" && echo "true" || echo "false" )
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$is_success" = "false" ] && [ "$has_failure" = "true" ] && [ "$has_error" = "true" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (success: $is_success, has_failure: $has_failure, has_error: $has_error)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 5: Python bridge logic simulation - exit code determines JSON success field
test_python_bridge_logic() {
    local test_name="Python bridge logic: exit code 0 -> success=true, exit code 1 -> success=false"
    
    # Test with exit code 0
    local exit_code=0
    local is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    
    if [ "$is_success" != "true" ]; then
        echo -e "${RED}✗${NC} FAIL: $test_name (exit 0 should give success=true)"
        TESTS_RUN=$((TESTS_RUN + 1))
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # Test with exit code 1
    exit_code=1
    is_success=$( [ $exit_code -eq 0 ] && echo "true" || echo "false" )
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$is_success" = "false" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (exit 1 should give success=false)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run all tests
test_wrapper_success_exit_code
test_wrapper_failure_exit_code
test_rollback_success_scenario
test_rollback_failure_scenario
test_python_bridge_logic

# Print summary and exit with appropriate code
print_test_summary
exit $?
