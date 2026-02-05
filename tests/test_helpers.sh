#!/bin/bash
# Shared test helper functions for GitUtil test suite

# Test counters (these will be used in each test file)
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

# Print test summary
print_test_summary() {
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
        return 1
    else
        return 0
    fi
}
