#!/bin/bash
# Git branch revert tool with step tracking and transactional behavior
# Usage: ./revert_branch.sh <repo_path> <commit_hash>

REPO_PATH="$1"
COMMIT_HASH="$2"

# Step tracking functions
report_step() {
    echo "STEP_STATUS:$1:$2"  # Format: STEP_STATUS:<step_name>:<status>
}

report_step_detail() {
    echo "STEP_DETAIL:$1"  # Format: STEP_DETAIL:<message>
}

# Rollback function to restore state on failure
rollback_changes() {
    local backup_branch="$1"
    local original_head="$2"
    
    report_step_detail "Transaction failed - initiating rollback"
    
    if [ -n "$backup_branch" ] && git rev-parse --verify "$backup_branch" >/dev/null 2>&1; then
        report_step_detail "Restoring from backup branch: $backup_branch"
        git reset --hard "$backup_branch" 2>/dev/null
        git branch -D "$backup_branch" 2>/dev/null
        report_step_detail "State restored to original HEAD: $original_head"
    fi
}

if [ -z "$REPO_PATH" ] || [ -z "$COMMIT_HASH" ]; then
    echo "ERROR: Missing arguments"
    echo "Usage: $0 <repo_path> <commit_hash>"
    exit 1
fi

# Step 1: Validate repository
report_step "validate" "in_progress"
if [ ! -d "$REPO_PATH/.git" ]; then
    report_step "validate" "failed"
    echo "ERROR: Not a git repository: $REPO_PATH"
    exit 1
fi

cd "$REPO_PATH" || exit 1

# Verify commit exists
if ! git rev-parse --verify "$COMMIT_HASH" >/dev/null 2>&1; then
    report_step "validate" "failed"
    echo "ERROR: Commit $COMMIT_HASH not found in repository"
    exit 1
fi
report_step "validate" "completed"

# Step 2: Create backup branch
report_step "backup" "in_progress"
TIMESTAMP=$(date +%Y%m%d_%H%M%S_%N | cut -c1-21)  # Include nanoseconds for uniqueness
CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)
BACKUP_BRANCH=""

if [ -n "$CURRENT_HEAD" ]; then
    BACKUP_BRANCH="backup/before-rollback-${TIMESTAMP}"
    report_step_detail "Creating backup branch: $BACKUP_BRANCH"
    git branch "$BACKUP_BRANCH" "$CURRENT_HEAD" 2>/dev/null
    if [ $? -eq 0 ]; then
        report_step_detail "Backup branch created successfully"
        report_step "backup" "completed"
    else
        report_step "backup" "failed"
        report_step_detail "Failed to create backup branch"
        echo "ERROR: Failed to create backup branch"
        exit 1
    fi
else
    report_step "backup" "failed"
    echo "ERROR: Could not determine current HEAD"
    exit 1
fi

# Step 3: Reset to target commit
report_step "reset" "in_progress"
report_step_detail "Reverting branch to commit: $COMMIT_HASH"
git reset --hard "$COMMIT_HASH" 2>/dev/null

if [ $? -ne 0 ]; then
    report_step "reset" "failed"
    report_step_detail "Git reset failed"
    # Rollback the transaction
    rollback_changes "$BACKUP_BRANCH" "$CURRENT_HEAD"
    echo "ERROR: Failed to revert branch - changes rolled back"
    exit 1
fi
report_step "reset" "completed"

# Step 4: Push to remote
report_step "push" "in_progress"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
report_step_detail "Pushing changes to remote branch: $CURRENT_BRANCH"

# Check if remote exists
if git remote | grep -q "^origin$"; then
    # Note: --force-with-lease provides safety by checking that the remote branch
    # matches the state of the local tracking branch
    git push --force-with-lease origin "$CURRENT_BRANCH" 2>/dev/null

    if [ $? -eq 0 ]; then
        report_step "push" "completed"
        report_step_detail "Successfully pushed to remote"
        echo "SUCCESS: Branch reverted to $COMMIT_HASH and pushed to remote"
        # Keep backup branch for user reference (not deleted on success)
        exit 0
    else
        report_step "push" "failed"
        report_step_detail "Push to remote failed"
        # Rollback the transaction
        rollback_changes "$BACKUP_BRANCH" "$CURRENT_HEAD"
        echo "ERROR: Push to remote failed - changes rolled back"
        echo "The rollback was aborted to maintain consistency with remote"
        exit 1
    fi
else
    # No remote configured - skip push and succeed
    report_step "push" "completed"
    report_step_detail "No remote configured - push skipped"
    echo "SUCCESS: Branch reverted to $COMMIT_HASH (local only, no remote configured)"
    # Keep backup branch for user reference (not deleted on success)
    exit 0
fi
