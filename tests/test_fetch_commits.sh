#!/bin/bash
# Tests for fetch_commits.sh script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FETCH_SCRIPT="$REPO_ROOT/scripts/fetch_commits.sh"

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
echo "Testing fetch_commits.sh"
echo "========================"
echo ""

setup

# Test 1: Error handling for non-git repository
echo "Test Group: Error Handling"
mkdir -p "$TEST_DIR/not_a_repo"
assert_failure "Fails on non-git repository" \
    "$FETCH_SCRIPT '$TEST_DIR/not_a_repo'"
assert_output_contains "Shows error message for non-git repository" \
    "$FETCH_SCRIPT '$TEST_DIR/not_a_repo'" \
    "ERROR"

# Test 2: Fetch commits from valid repository
echo ""
echo "Test Group: Valid Repository with Commits"
git init -q "$TEST_DIR/test_repo"
cd "$TEST_DIR/test_repo"
git config user.email "test@example.com"
git config user.name "Test User"
echo "initial content" > file.txt
git add file.txt
git commit -q -m "Initial commit"
echo "more content" >> file.txt
git add file.txt
git commit -q -m "Second commit"
cd - > /dev/null

assert_success "Succeeds on valid repository" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'"

# Test 3: Output format validation
echo ""
echo "Test Group: Output Format"
assert_output_contains "Output contains COMMIT_START marker" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "COMMIT_START"
assert_output_contains "Output contains COMMIT_END marker" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "COMMIT_END"
assert_output_contains "Output contains HASH field" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "HASH:"
assert_output_contains "Output contains AUTHOR field" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "AUTHOR:"
assert_output_contains "Output contains TIMESTAMP field" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "TIMESTAMP:"
assert_output_contains "Output contains SUBJECT field" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "SUBJECT:"

# Test 4: Commit content verification
echo ""
echo "Test Group: Commit Content"
assert_output_contains "Shows commit message" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "Initial commit"
assert_output_contains "Shows author name" \
    "$FETCH_SCRIPT '$TEST_DIR/test_repo'" \
    "Test User"

# Test 5: Multiple commits
echo ""
echo "Test Group: Multiple Commits"
OUTPUT=$($FETCH_SCRIPT "$TEST_DIR/test_repo")
COMMIT_COUNT=$(echo "$OUTPUT" | grep -c "COMMIT_START")
TESTS_RUN=$((TESTS_RUN + 1))
if [ "$COMMIT_COUNT" -eq 2 ]; then
    echo -e "${GREEN}✓${NC} PASS: Shows all commits (found $COMMIT_COUNT commits)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Shows all commits (expected 2 commits, found $COMMIT_COUNT)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: Default path (current directory)
echo ""
echo "Test Group: Default Path Handling"
cd "$TEST_DIR/test_repo"
assert_success "Uses current directory when no argument provided" \
    "$FETCH_SCRIPT"
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
