#!/bin/bash
# Tests for revert_branch.sh script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REVERT_SCRIPT="$REPO_ROOT/scripts/revert_branch.sh"

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
# Note: May show SUCCESS (if remote push succeeds) or WARNING (if no remote configured)
# Both are valid outcomes - the key is that the local revert succeeds
TESTS_RUN=$((TESTS_RUN + 1))
OUTPUT=$($REVERT_SCRIPT "$TEST_DIR/test_repo" "$THIRD_COMMIT" 2>&1)
if echo "$OUTPUT" | grep -qE "(SUCCESS|WARNING)"; then
    echo -e "${GREEN}✓${NC} PASS: Shows completion message (SUCCESS or WARNING)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Does not show completion message"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

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

# Test 7: Backup branch creation
echo ""
echo "Test Group: Backup Branch Creation"
# Setup: Create a fresh test repo with multiple commits
git init -q "$TEST_DIR/test_backup_repo"
cd "$TEST_DIR/test_backup_repo"
git config user.email "test@example.com"
git config user.name "Test User"

# Create commits
echo "v1" > file.txt
git add file.txt
git commit -q -m "Commit 1"
BACKUP_FIRST=$(git rev-parse HEAD)

echo "v2" > file.txt
git add file.txt
git commit -q -m "Commit 2"
BACKUP_SECOND=$(git rev-parse HEAD)

echo "v3" > file.txt
git add file.txt
git commit -q -m "Commit 3"
BACKUP_THIRD=$(git rev-parse HEAD)

cd - > /dev/null

# Perform rollback from third to first commit
$REVERT_SCRIPT "$TEST_DIR/test_backup_repo" "$BACKUP_FIRST" > /dev/null 2>&1

# Check that a backup branch was created
cd "$TEST_DIR/test_backup_repo"
BACKUP_BRANCHES=$(git branch --list "backup/before-rollback-*" | wc -l)
cd - > /dev/null

TESTS_RUN=$((TESTS_RUN + 1))
if [ "$BACKUP_BRANCHES" -ge 1 ]; then
    echo -e "${GREEN}✓${NC} PASS: Backup branch was created"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: No backup branch found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Verify backup branch points to the correct commit (the third commit, before rollback)
cd "$TEST_DIR/test_backup_repo"
# Get the most recently created backup branch (sorted by name which includes timestamp)
BACKUP_BRANCH_NAME=$(git branch --list "backup/before-rollback-*" | sort | tail -1 | tr -d ' ')
if [ -n "$BACKUP_BRANCH_NAME" ]; then
    BACKUP_BRANCH_COMMIT=$(git rev-parse "$BACKUP_BRANCH_NAME" 2>/dev/null)
    cd - > /dev/null
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$BACKUP_BRANCH_COMMIT" = "$BACKUP_THIRD" ]; then
        echo -e "${GREEN}✓${NC} PASS: Backup branch points to correct commit (pre-rollback HEAD)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: Backup branch points to wrong commit (expected $BACKUP_THIRD, got $BACKUP_BRANCH_COMMIT)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    cd - > /dev/null
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${RED}✗${NC} FAIL: Could not verify backup branch commit (no backup branch name found)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Push functionality with remote repository
echo ""
echo "Test Group: Push Functionality"
# Create a bare repository to act as remote
git init -q --bare "$TEST_DIR/remote_repo.git"

# Create a local repository
git init -q "$TEST_DIR/local_repo"
cd "$TEST_DIR/local_repo"
git config user.email "test@example.com"
git config user.name "Test User"

# Add remote
git remote add origin "$TEST_DIR/remote_repo.git"

# Create commits
echo "v1" > file.txt
git add file.txt
git commit -q -m "Commit 1"
REMOTE_FIRST=$(git rev-parse HEAD)

echo "v2" > file.txt
git add file.txt
git commit -q -m "Commit 2"

echo "v3" > file.txt
git add file.txt
git commit -q -m "Commit 3"
REMOTE_THIRD=$(git rev-parse HEAD)

# Push to remote - try main branch first, then master
PUSH_OUTPUT=$(git push -q origin main 2>&1 || git push -q origin master 2>&1)
if [ $? -ne 0 ]; then
    echo "Test setup error: Failed to push to remote"
    echo "$PUSH_OUTPUT"
fi

cd - > /dev/null

# Perform rollback to first commit
OUTPUT=$($REVERT_SCRIPT "$TEST_DIR/local_repo" "$REMOTE_FIRST" 2>&1)

# Check that SUCCESS message is shown (not WARNING, since remote exists)
TESTS_RUN=$((TESTS_RUN + 1))
if echo "$OUTPUT" | grep -q "SUCCESS.*pushed to remote"; then
    echo -e "${GREEN}✓${NC} PASS: Shows SUCCESS message when push succeeds"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Does not show SUCCESS message for successful push"
    echo "Output was: $OUTPUT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Verify the remote was actually updated
cd "$TEST_DIR/local_repo"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
cd - > /dev/null

cd "$TEST_DIR/remote_repo.git"
REMOTE_HEAD=$(git rev-parse "$CURRENT_BRANCH" 2>/dev/null)
cd - > /dev/null

TESTS_RUN=$((TESTS_RUN + 1))
if [ "$REMOTE_HEAD" = "$REMOTE_FIRST" ]; then
    echo -e "${GREEN}✓${NC} PASS: Remote repository was updated to rollback commit"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Remote repository was not updated (expected $REMOTE_FIRST, got $REMOTE_HEAD)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 9: Verify backup branch is pushed to remote
echo ""
echo "Test Group: Backup Branch Push to Remote"
# Check if backup branch exists on remote
cd "$TEST_DIR/remote_repo.git"
REMOTE_BACKUP_BRANCHES=$(git branch --list "backup/before-rollback-*" | wc -l)
cd - > /dev/null

TESTS_RUN=$((TESTS_RUN + 1))
if [ "$REMOTE_BACKUP_BRANCHES" -ge 1 ]; then
    echo -e "${GREEN}✓${NC} PASS: Backup branch was pushed to remote repository"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗${NC} FAIL: Backup branch was not found on remote repository"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Verify the remote backup branch points to the correct commit (pre-rollback HEAD)
cd "$TEST_DIR/remote_repo.git"
REMOTE_BACKUP_BRANCH_NAME=$(git branch --list "backup/before-rollback-*" | sort | tail -1 | tr -d ' ')
if [ -n "$REMOTE_BACKUP_BRANCH_NAME" ]; then
    REMOTE_BACKUP_COMMIT=$(git rev-parse "$REMOTE_BACKUP_BRANCH_NAME" 2>/dev/null)
    cd - > /dev/null
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$REMOTE_BACKUP_COMMIT" = "$REMOTE_THIRD" ]; then
        echo -e "${GREEN}✓${NC} PASS: Remote backup branch points to correct commit (pre-rollback HEAD)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} FAIL: Remote backup branch points to wrong commit (expected $REMOTE_THIRD, got $REMOTE_BACKUP_COMMIT)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    cd - > /dev/null
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${RED}✗${NC} FAIL: Could not find backup branch on remote to verify commit"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi


teardown

# Print summary and exit
print_test_summary
exit $?
