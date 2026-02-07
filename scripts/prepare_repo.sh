#!/bin/bash
# Repository preparation tool - handles cloning of remote repositories
# Usage: ./prepare_repo.sh <repo_url_or_path>

REPO_INPUT="$1"
DEFAULT_REPOS_DIR="${GITUTIL_REPOS_DIR:-$HOME/.gitutil/repos}"

if [ -z "$REPO_INPUT" ]; then
    echo "ERROR: Repository URL or path required"
    echo "Usage: $0 <repo_url_or_path>"
    exit 1
fi

# Function to check if input is a URL
is_remote_url() {
    local input="$1"
    # Check for common git URL patterns (including file://)
    if [[ "$input" =~ ^(https?|git|ssh|ftps?|file)://.*\.git$ ]] || \
       [[ "$input" =~ ^git@.*:.*\.git$ ]] || \
       [[ "$input" =~ ^(https?|git|ssh|ftps?|file)://.*/.*$ ]]; then
        return 0
    fi
    return 1
}

# Function to get repository name from URL
get_repo_name() {
    local url="$1"
    # Extract repository name (last part of URL, without .git)
    local name=$(basename "$url" .git)
    echo "$name"
}

# Check if input is a remote URL
if is_remote_url "$REPO_INPUT"; then
    # It's a remote repository - prepare to clone
    REPO_NAME=$(get_repo_name "$REPO_INPUT")
    LOCAL_PATH="$DEFAULT_REPOS_DIR/$REPO_NAME"
    
    # Create default repos directory if it doesn't exist
    if [ ! -d "$DEFAULT_REPOS_DIR" ]; then
        mkdir -p "$DEFAULT_REPOS_DIR" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to create directory: $DEFAULT_REPOS_DIR"
            exit 1
        fi
    fi
    
    # Check if repository already exists locally
    if [ -d "$LOCAL_PATH/.git" ]; then
        # Repository already cloned, just return the path
        echo "$LOCAL_PATH"
        exit 0
    fi
    
    # Clone the repository (disable terminal prompts and set timeout)
    # GIT_TERMINAL_PROMPT=0 prevents credential prompts
    # GIT_SSH_COMMAND sets SSH options to fail fast without prompting
    # Using StrictHostKeyChecking=accept-new for better security
    if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new" \
         timeout 10 git clone "$REPO_INPUT" "$LOCAL_PATH" >/dev/null 2>&1; then
        echo "ERROR: Failed to clone repository from $REPO_INPUT"
        exit 1
    fi
    
    # Return the local path
    echo "$LOCAL_PATH"
    exit 0
else
    # It's a local path - expand and validate
    REPO_PATH="${REPO_INPUT/#\~/$HOME}"
    
    # Convert to absolute path if it exists
    if [ -d "$REPO_PATH" ]; then
        REPO_PATH="$(cd "$REPO_PATH" && pwd)"
    fi
    
    # Return the path
    echo "$REPO_PATH"
    exit 0
fi