#!/bin/bash
# Test suite for prepare_repo.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
PREPARE_REPO_SCRIPT="$REPO_ROOT/scripts/prepare_repo.sh"

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
    # Clean up any test gitutil directories
    if [ -d "$HOME/.gitutil_test_repos_$$" ]; then
        rm -rf "$HOME/.gitutil_test_repos_$$"
    fi
}

# Run tests
echo "Testing prepare_repo.sh"
echo "========================"
echo ""

setup

# Test 1: No arguments
echo "Test Group: Argument Validation"
assert_failure "Fails when no arguments provided" \
    "$PREPARE_REPO_SCRIPT"
assert_output_contains "Shows error for missing arguments" \
    "$PREPARE_REPO_SCRIPT" \
    "ERROR"

# Test 2: Local path handling - existing directory
echo ""
echo "Test Group: Local Path Handling"
git init -q "$TEST_DIR/local_repo"
assert_success "Handles existing local path" \
    "$PREPARE_REPO_SCRIPT '$TEST_DIR/local_repo'"
assert_output_contains "Returns valid path" \
    "$PREPARE_REPO_SCRIPT '$TEST_DIR/local_repo'" \
    "$TEST_DIR/local_repo"

# Test 3: Tilde expansion
mkdir -p "$HOME/.gitutil_test_$$"
git init -q "$HOME/.gitutil_test_$$"
assert_success "Expands tilde in path" \
    "$PREPARE_REPO_SCRIPT '~/.gitutil_test_$$'"
assert_output_contains "Tilde expands to home" \
    "$PREPARE_REPO_SCRIPT '~/.gitutil_test_$$'" \
    "$HOME"
rm -rf "$HOME/.gitutil_test_$$"

# Test 4: Relative path handling
echo ""
echo "Test Group: Relative Paths"
cd "$TEST_DIR"
mkdir -p "relative_repo"
git init -q "relative_repo"
assert_success "Handles relative paths" \
    "$PREPARE_REPO_SCRIPT 'relative_repo'"
cd - > /dev/null

# Test 5: URL detection - should recognize URLs even if clone fails
echo ""
echo "Test Group: URL Detection"
# These will fail to clone but should recognize the URL format
output=$("$PREPARE_REPO_SCRIPT" "https://github.com/user/repo.git" 2>&1)
if echo "$output" | grep -q "ERROR"; then
    echo -e "${GREEN}✓${NC} PASS: Recognizes HTTPS URLs (clone attempted)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Should attempt to clone HTTPS URL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

output=$("$PREPARE_REPO_SCRIPT" "git@github.com:user/repo.git" 2>&1)
if echo "$output" | grep -q "ERROR"; then
    echo -e "${GREEN}✓${NC} PASS: Recognizes SSH URLs (clone attempted)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Should attempt to clone SSH URL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 6: Local file:// URL cloning
echo ""
echo "Test Group: Repository Cloning"
# Create a source repository
git init -q "$TEST_DIR/source_repo"
cd "$TEST_DIR/source_repo"
git config user.email "test@test.com"
git config user.name "Test User"
echo "test" > test.txt
git add .
git commit -q -m "Initial commit"
cd - > /dev/null

# Clone using file:// protocol
test_gitutil_dir="$TEST_DIR/gitutil_repos"
export GITUTIL_REPOS_DIR="$test_gitutil_dir"
assert_success "Clones repository with file:// protocol" \
    "$PREPARE_REPO_SCRIPT 'file://$TEST_DIR/source_repo'"

# Check that default directory was created
if [ -d "$test_gitutil_dir" ]; then
    echo -e "${GREEN}✓${NC} PASS: Creates default repos directory"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Should create default repos directory"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 7: Already cloned repo
mkdir -p "$test_gitutil_dir/existing"
git init -q "$test_gitutil_dir/existing"
output=$("$PREPARE_REPO_SCRIPT" "https://github.com/user/existing.git" 2>&1)
if [ $? -eq 0 ] && echo "$output" | grep -q "$test_gitutil_dir/existing"; then
    echo -e "${GREEN}✓${NC} PASS: Returns existing cloned repo"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo -e "${RED}✗${NC} FAIL: Should return existing repo path"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

unset GITUTIL_REPOS_DIR

teardown

# Print summary and exit
print_test_summary
exit $?
