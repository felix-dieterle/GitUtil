#!/bin/bash
# Test suite for cleanup_repo.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CLEANUP_REPO_SCRIPT="$REPO_ROOT/scripts/cleanup_repo.sh"

# Source shared test helpers
source "$SCRIPT_DIR/test_helpers.sh"

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
echo "Testing cleanup_repo.sh"
echo "======================="
echo ""

setup

# Test 1: No arguments
echo "Test Group: Argument Validation"
assert_failure "Fails when no arguments provided" \
    "$CLEANUP_REPO_SCRIPT"
assert_output_contains "Shows error for missing arguments" \
    "$CLEANUP_REPO_SCRIPT" \
    "ERROR"

# Test 2: Non-existent directory
echo ""
echo "Test Group: Path Validation"
assert_failure "Fails on non-existent path" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/nonexistent'"
assert_output_contains "Shows error for non-existent path" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/nonexistent'" \
    "ERROR"

# Test 3: Not a git repository
mkdir -p "$TEST_DIR/not_a_repo"
assert_failure "Fails on non-git directory" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/not_a_repo'"
assert_output_contains "Shows error for non-git directory" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/not_a_repo'" \
    "Not a git repository"

# Test 4: Successful deletion
echo ""
echo "Test Group: Repository Deletion"
git init -q "$TEST_DIR/test_repo"
cd "$TEST_DIR/test_repo"
git config user.email "test@test.com"
git config user.name "Test User"
echo "test file" > test.txt
git add .
git commit -q -m "Test commit"
cd - > /dev/null

assert_success "Successfully deletes valid repository" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/test_repo'"

# Create another repo for success message test
git init -q "$TEST_DIR/test_repo_2"
assert_output_contains "Shows success message" \
    "$CLEANUP_REPO_SCRIPT '$TEST_DIR/test_repo_2'" \
    "SUCCESS"

# Test 5: Verify repository is deleted
git init -q "$TEST_DIR/verify_delete"
"$CLEANUP_REPO_SCRIPT" "$TEST_DIR/verify_delete" > /dev/null 2>&1
if [ ! -d "$TEST_DIR/verify_delete" ]; then
    echo -e "${GREEN}✓${NC} PASS: Repository directory is deleted"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Repository directory should be deleted"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 6: Tilde expansion
mkdir -p "$HOME/.gitutil_cleanup_test_$$"
git init -q "$HOME/.gitutil_cleanup_test_$$"
assert_success "Expands tilde in path" \
    "$CLEANUP_REPO_SCRIPT '~/.gitutil_cleanup_test_$$'"
if [ ! -d "$HOME/.gitutil_cleanup_test_$$" ]; then
    echo -e "${GREEN}✓${NC} PASS: Repository deleted with tilde path"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Repository should be deleted with tilde path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    rm -rf "$HOME/.gitutil_cleanup_test_$$"
fi

teardown

# Print summary and exit
print_test_summary
exit $?
