# GitUtil Tests

This directory contains comprehensive tests for the GitUtil shell scripts.

## Test Coverage

The test suite validates the core functionality of three main scripts:

1. **validate_repo.sh** - Repository validation tests
   - Valid repository detection
   - Invalid repository detection
   - Non-existent path handling
   - Default path behavior

2. **fetch_commits.sh** - Commit fetching tests
   - Error handling for non-git repositories
   - Valid repository processing
   - Output format validation
   - Commit content verification
   - Multiple commits handling
   - Default path behavior

3. **revert_branch.sh** - Branch revert tests
   - Argument validation
   - Repository validation
   - Valid revert operations
   - Revert verification
   - File content verification
   - Invalid commit hash handling

## Running Tests

### Run All Tests

To run the complete test suite:

```bash
./tests/run_tests.sh
```

### Run Individual Test Files

To run tests for a specific script:

```bash
./tests/test_validate_repo.sh
./tests/test_fetch_commits.sh
./tests/test_revert_branch.sh
```

## Test Framework

The tests use a lightweight bash testing framework with the following assertion functions:

- `assert_success` - Verifies a command succeeds (exit code 0)
- `assert_failure` - Verifies a command fails (non-zero exit code)
- `assert_output_contains` - Verifies command output contains expected text

Each test file includes:
- Setup and teardown functions for test isolation
- Color-coded output (green for pass, red for fail)
- Detailed test summaries
- Proper exit codes for CI/CD integration

## Test Isolation

All tests run in temporary directories created with `mktemp -d` and are cleaned up after execution. This ensures:
- No interference between test runs
- No pollution of the repository
- Safe parallel execution capability

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

This makes the test suite compatible with CI/CD pipelines and automated testing workflows.
