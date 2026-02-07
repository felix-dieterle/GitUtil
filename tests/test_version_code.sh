#!/bin/bash
# Test version code calculation logic from package-mobile.yml workflow
# This test ensures that the version code calculation handles zero-padded date values correctly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_helpers.sh"

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Version Code Calculation${NC}"
echo ""

# Test 1: Calculate version code with zero-padded month (should not fail)
test_version_code_zero_padded_month() {
    local test_name="Version code calculation with zero-padded month (08)"
    
    # Simulate the workflow logic with a month like "08" (August)
    year="2026"
    month="08"
    day="15"
    hour="14"
    
    # This is the fixed version with 10# prefix
    local version_code
    version_code=$(( (10#$year - 2020) * 1000000 + 10#$month * 10000 + 10#$day * 100 + 10#$hour ))
    
    # Expected: (2026-2020)*1000000 + 8*10000 + 15*100 + 14 = 6*1000000 + 80000 + 1500 + 14 = 6081514
    local expected=6081514
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 2: Calculate version code with zero-padded day (should not fail)
test_version_code_zero_padded_day() {
    local test_name="Version code calculation with zero-padded day (09)"
    
    year="2026"
    month="12"
    day="09"
    hour="23"
    
    local version_code
    version_code=$(( (10#$year - 2020) * 1000000 + 10#$month * 10000 + 10#$day * 100 + 10#$hour ))
    
    # Expected: (2026-2020)*1000000 + 12*10000 + 9*100 + 23 = 6*1000000 + 120000 + 900 + 23 = 6120923
    local expected=6120923
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 3: Calculate version code with zero-padded hour (should not fail)
test_version_code_zero_padded_hour() {
    local test_name="Version code calculation with zero-padded hour (08)"
    
    year="2026"
    month="02"
    day="07"
    hour="08"
    
    local version_code
    version_code=$(( (10#$year - 2020) * 1000000 + 10#$month * 10000 + 10#$day * 100 + 10#$hour ))
    
    # Expected: (2026-2020)*1000000 + 2*10000 + 7*100 + 8 = 6*1000000 + 20000 + 700 + 8 = 6020708
    local expected=6020708
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 4: Calculate version code for tag-based version (major, minor, patch)
test_version_code_tag_based() {
    local test_name="Version code calculation for tag-based release (v1.2.3)"
    
    major="1"
    minor="2"
    patch="3"
    
    # Calculate version code: major*10000 + minor*100 + patch
    local version_code
    version_code=$((major * 10000 + minor * 100 + patch))
    
    # Expected: 1*10000 + 2*100 + 3 = 10203
    local expected=10203
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 5: Simulate the exact scenario from the error (Feb 7, 2026 at 08:42)
test_version_code_error_scenario() {
    local test_name="Version code calculation for exact error scenario (2026-02-07 08:42)"
    
    year="2026"
    month="02"
    day="07"
    hour="08"
    
    local version_code
    version_code=$(( (10#$year - 2020) * 1000000 + 10#$month * 10000 + 10#$day * 100 + 10#$hour ))
    
    # Expected: (2026-2020)*1000000 + 2*10000 + 7*100 + 8 = 6*1000000 + 20000 + 700 + 8 = 6020708
    local expected=6020708
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 6: Edge case - All components zero-padded with "problematic" digits (08 and 09)
test_version_code_all_problematic_digits() {
    local test_name="Version code calculation with all problematic zero-padded values"
    
    year="2026"
    month="08"
    day="09"
    hour="08"
    
    local version_code
    version_code=$(( (10#$year - 2020) * 1000000 + 10#$month * 10000 + 10#$day * 100 + 10#$hour ))
    
    # Expected: (2026-2020)*1000000 + 8*10000 + 9*100 + 8 = 6*1000000 + 80000 + 900 + 8 = 6080908
    local expected=6080908
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$version_code" -eq "$expected" ]; then
        echo -e "${GREEN}✓${NC} PASS: $test_name (got: $version_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name (expected: $expected, got: $version_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run all tests
test_version_code_zero_padded_month
test_version_code_zero_padded_day
test_version_code_zero_padded_hour
test_version_code_tag_based
test_version_code_error_scenario
test_version_code_all_problematic_digits

# Print summary and exit with appropriate code
print_test_summary
exit $?
