#!/bin/bash
# Tests for validate_repo.sh script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate_repo.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test helper functions
assert_success() {
    local test_name="$1"
    local command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_failure() {
    local test_name="$1"
    local command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_output_contains() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local output
    output=$(eval "$command" 2>&1)
    
    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected '$expected', got '$output')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Setup
setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
}

# Teardown
teardown() {
    # Clean up temporary test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Run tests
echo "Testing validate_repo.sh"
echo "========================"
echo ""

setup

# Test 1: Valid git repository
echo "Test Group: Valid Repository Detection"
git init -q "$TEST_DIR/valid_repo"
assert_output_contains "Detects valid git repository" \
    "$VALIDATE_SCRIPT '$TEST_DIR/valid_repo'" \
    "VALID"
assert_success "Returns exit code 0 for valid repo" \
    "$VALIDATE_SCRIPT '$TEST_DIR/valid_repo'"

# Test 2: Invalid repository (no .git directory)
echo ""
echo "Test Group: Invalid Repository Detection"
mkdir -p "$TEST_DIR/invalid_repo"
assert_output_contains "Detects invalid repository" \
    "$VALIDATE_SCRIPT '$TEST_DIR/invalid_repo'" \
    "INVALID"
assert_failure "Returns exit code 1 for invalid repo" \
    "$VALIDATE_SCRIPT '$TEST_DIR/invalid_repo'"

# Test 3: Non-existent path
echo ""
echo "Test Group: Non-existent Path"
assert_failure "Handles non-existent path" \
    "$VALIDATE_SCRIPT '$TEST_DIR/nonexistent'"

# Test 4: Current directory as default
echo ""
echo "Test Group: Default Path Handling"
cd "$TEST_DIR/valid_repo"
assert_success "Uses current directory when no argument provided" \
    "$VALIDATE_SCRIPT"
cd - > /dev/null

teardown

# Print summary
echo ""
echo "========================"
echo "Test Summary"
echo "========================"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
else
    echo -e "Tests failed: $TESTS_FAILED"
fi
echo ""

# Exit with failure if any tests failed
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
