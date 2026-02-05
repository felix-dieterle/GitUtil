#!/bin/bash
# Tests for revert_branch.sh script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REVERT_SCRIPT="$REPO_ROOT/scripts/revert_branch.sh"

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
        echo -e "${RED}✗${NC} FAIL: $test_name (expected to find '$expected')"
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
echo "Testing revert_branch.sh"
echo "========================"
echo ""

setup

# Test 1: Missing arguments
echo "Test Group: Argument Validation"
assert_failure "Fails when no arguments provided" \
    "$REVERT_SCRIPT"
assert_output_contains "Shows error for missing arguments" \
    "$REVERT_SCRIPT" \
    "ERROR"
assert_failure "Fails when only repo path provided" \
    "$REVERT_SCRIPT /tmp/test"
assert_output_contains "Shows usage message for missing commit hash" \
    "$REVERT_SCRIPT /tmp/test" \
    "Usage"

# Test 2: Invalid repository
echo ""
echo "Test Group: Repository Validation"
mkdir -p "$TEST_DIR/not_a_repo"
assert_failure "Fails on non-git repository" \
    "$REVERT_SCRIPT '$TEST_DIR/not_a_repo' abc123"
assert_output_contains "Shows error for invalid repository" \
    "$REVERT_SCRIPT '$TEST_DIR/not_a_repo' abc123" \
    "ERROR"

# Test 3: Valid revert operation
echo ""
echo "Test Group: Valid Revert Operation"
git init -q "$TEST_DIR/test_repo"
cd "$TEST_DIR/test_repo"
git config user.email "test@example.com"
git config user.name "Test User"

# Create first commit
echo "version 1" > file.txt
git add file.txt
git commit -q -m "First commit"
FIRST_COMMIT=$(git rev-parse HEAD)

# Create second commit
echo "version 2" > file.txt
git add file.txt
git commit -q -m "Second commit"

# Create third commit
echo "version 3" > file.txt
git add file.txt
git commit -q -m "Third commit"
THIRD_COMMIT=$(git rev-parse HEAD)

cd - > /dev/null

assert_success "Successfully reverts to valid commit" \
    "$REVERT_SCRIPT '$TEST_DIR/test_repo' $FIRST_COMMIT"
assert_output_contains "Shows success message" \
    "$REVERT_SCRIPT '$TEST_DIR/test_repo' $THIRD_COMMIT" \
    "SUCCESS"

# Test 4: Verify revert actually worked
echo ""
echo "Test Group: Revert Verification"
# Revert to first commit
$REVERT_SCRIPT "$TEST_DIR/test_repo" "$FIRST_COMMIT" > /dev/null 2>&1
cd "$TEST_DIR/test_repo"
CURRENT_COMMIT=$(git rev-parse HEAD)
cd - > /dev/null

TESTS_RUN=$((TESTS_RUN + 1))
if [ "$CURRENT_COMMIT" = "$FIRST_COMMIT" ]; then
    echo -e "${GREEN}✓${NC} PASS: Branch HEAD matches target commit after revert"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Branch HEAD does not match target commit"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: File content verification
TESTS_RUN=$((TESTS_RUN + 1))
FILE_CONTENT=$(cat "$TEST_DIR/test_repo/file.txt")
if [ "$FILE_CONTENT" = "version 1" ]; then
    echo -e "${GREEN}✓${NC} PASS: File content matches expected state after revert"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: File content does not match (expected 'version 1', got '$FILE_CONTENT')"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Invalid commit hash
echo ""
echo "Test Group: Invalid Commit Hash"
assert_failure "Fails on invalid commit hash" \
    "$REVERT_SCRIPT '$TEST_DIR/test_repo' invalid_hash_12345"

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
