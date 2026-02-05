#!/bin/bash
# Test runner for GitUtil scripts
# Runs all test scripts and reports overall results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GitUtil Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track overall results
TOTAL_TEST_FILES=0
PASSED_TEST_FILES=0
FAILED_TEST_FILES=0

# Find and run all test scripts
for test_file in "$SCRIPT_DIR"/test_*.sh; do
    if [ -f "$test_file" ]; then
        TOTAL_TEST_FILES=$((TOTAL_TEST_FILES + 1))
        
        echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
        echo ""
        
        # Run the test and capture exit code
        bash "$test_file"
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            PASSED_TEST_FILES=$((PASSED_TEST_FILES + 1))
        else
            FAILED_TEST_FILES=$((FAILED_TEST_FILES + 1))
        fi
        
        echo ""
        echo "----------------------------------------"
        echo ""
    fi
done

# Print overall summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Overall Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Test files run:    $TOTAL_TEST_FILES"
echo -e "Test files passed: ${GREEN}$PASSED_TEST_FILES${NC}"

if [ $FAILED_TEST_FILES -gt 0 ]; then
    echo -e "Test files failed: ${RED}$FAILED_TEST_FILES${NC}"
    echo ""
    echo -e "${RED}TESTS FAILED${NC}"
    exit 1
else
    echo -e "Test files failed: $FAILED_TEST_FILES"
    echo ""
    echo -e "${GREEN}ALL TESTS PASSED${NC}"
    exit 0
fi
