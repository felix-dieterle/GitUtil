#!/bin/bash
# Tests for validate_repo.sh script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VALIDATE_SCRIPT="$REPO_ROOT/scripts/validate_repo.sh"

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

# Print summary and exit
print_test_summary
exit $?
