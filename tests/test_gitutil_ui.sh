#!/bin/bash
# Test suite for gitutil.sh interactive UI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
GITUTIL="$PROJECT_DIR/gitutil.sh"

# Colors for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass_test() {
    echo -e "${GREEN}✓ $1${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail_test() {
    echo -e "${RED}✗ $1${NC}"
    echo "  $2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Setup test repository
setup_test_repo() {
    local repo_path="$1"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"
    echo "file1" > file1.txt
    git add . > /dev/null 2>&1
    git commit -q -m "First commit"
    echo "file2" > file2.txt
    git add . > /dev/null 2>&1
    git commit -q -m "Second commit"
    echo "file3" > file3.txt
    git add . > /dev/null 2>&1
    git commit -q -m "Third commit"
    cd - > /dev/null
}

cleanup_test_repo() {
    local repo_path="$1"
    rm -rf "$repo_path"
}

# Strip ANSI color codes from output
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g' | sed 's/\x1b\[H\x1b\[2J//g'
}

echo "Running GitUtil UI Tests"
echo "========================"
echo ""

# Test 1: Check if gitutil.sh exists and is executable
if [ -x "$GITUTIL" ]; then
    pass_test "gitutil.sh exists and is executable"
else
    fail_test "gitutil.sh exists and is executable" "File not found or not executable"
fi

# Test 2: Check script dependencies exist
if [ -f "$PROJECT_DIR/scripts/validate_repo.sh" ] && \
   [ -f "$PROJECT_DIR/scripts/fetch_commits.sh" ] && \
   [ -f "$PROJECT_DIR/scripts/revert_branch.sh" ]; then
    pass_test "All required script dependencies exist"
else
    fail_test "All required script dependencies exist" "Missing script dependencies"
fi

# Test 3: Test basic invocation (exit immediately)
TEST_REPO=$(mktemp -d)
setup_test_repo "$TEST_REPO"

OUTPUT=$(printf "\n4\n" | timeout 5 "$GITUTIL" "$TEST_REPO" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -q "GitUtil"; then
    pass_test "UI launches successfully"
else
    fail_test "UI launches successfully" "UI failed to launch"
fi

# Test 4: Test menu display
if echo "$OUTPUT" | grep -q "Main Menu"; then
    pass_test "Main menu is displayed"
else
    fail_test "Main menu is displayed" "Main menu not found"
fi

# Test 5: Test repository validation
OUTPUT=$(printf "\n4\n" | timeout 5 "$GITUTIL" "$TEST_REPO" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -q "Valid git repository"; then
    pass_test "Repository validation works"
else
    fail_test "Repository validation works" "Validation message not found"
fi

# Test 6: Test commit history can be fetched (via menu option 2)
OUTPUT=$(printf "\n2\n\n4\n" | timeout 10 "$GITUTIL" "$TEST_REPO" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -q "Commit History" && echo "$OUTPUT" | grep -q "commit"; then
    pass_test "Commit history display works"
else
    fail_test "Commit history display works" "Commit history not displayed"
fi

# Test 7: Test invalid repository handling
INVALID_REPO=$(mktemp -d)

OUTPUT=$(printf "1\n$INVALID_REPO\n\n4\n" | timeout 5 "$GITUTIL" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -qi "invalid\|not exist\|not a git"; then
    pass_test "Invalid repository is detected"
else
    fail_test "Invalid repository is detected" "Invalid repo not detected"
fi
rm -rf "$INVALID_REPO"

# Test 8: Test color output is present (without stripping)
OUTPUT=$(printf "\n4\n" | timeout 5 "$GITUTIL" "$TEST_REPO" 2>&1 || true)
if echo "$OUTPUT" | grep -q $'\033\['; then
    pass_test "Color codes are present in output"
else
    fail_test "Color codes are present in output" "No ANSI color codes found"
fi

# Test 9: Test all menu options are present
OUTPUT=$(printf "\n4\n" | timeout 5 "$GITUTIL" "$TEST_REPO" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -q "Select repository" && \
   echo "$OUTPUT" | grep -q "View commit history" && \
   echo "$OUTPUT" | grep -q "Revert branch" && \
   echo "$OUTPUT" | grep -q "Exit"; then
    pass_test "All menu options are present"
else
    fail_test "All menu options are present" "Some menu options missing"
fi

# Test 10: Test graceful exit
OUTPUT=$(printf "\n4\n" | timeout 5 "$GITUTIL" "$TEST_REPO" 2>&1 | strip_colors || true)
if echo "$OUTPUT" | grep -q "Thank you"; then
    pass_test "Graceful exit message displayed"
else
    fail_test "Graceful exit message displayed" "Exit message not found"
fi

# Cleanup
cleanup_test_repo "$TEST_REPO"

# Summary
echo ""
echo "========================"
echo "Test Results:"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo "========================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
