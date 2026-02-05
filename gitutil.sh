#!/bin/bash
# GitUtil - Interactive Git Branch Rewind Tool
# A user-friendly interface for git repository management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print colored messages
print_header() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Format timestamp for display
format_timestamp() {
    local timestamp="$1"
    date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
    date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || \
    echo "$timestamp"
}

# Arrays to store commit information (indexed by commit number)
declare -a COMMIT_HASHES
declare -a COMMIT_SUBJECTS

# Clear screen and show header
show_main_header() {
    # Clear screen if TERM is set, otherwise just add some newlines
    if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
        clear 2>/dev/null || echo -e "\n\n\n"
    else
        echo -e "\n\n\n"
    fi
    print_header "GitUtil - Git Branch Rewind Tool"
    echo -e "${BOLD}Version 1.0${NC}\n"
}

# Get repository path from user
get_repository_path() {
    local default_path="."
    echo -e "${BOLD}Enter git repository path${NC} (press Enter for current directory):"
    echo -n "> "
    read -r repo_path
    
    if [ -z "$repo_path" ]; then
        repo_path="$default_path"
    fi
    
    # Expand ~ to home directory
    repo_path="${repo_path/#\~/$HOME}"
    
    # Convert to absolute path
    if [ -d "$repo_path" ]; then
        repo_path="$(cd "$repo_path" && pwd)"
    fi
    
    echo "$repo_path"
}

# Validate repository
validate_repository() {
    local repo_path="$1"
    
    if [ ! -d "$repo_path" ]; then
        print_error "Directory does not exist: $repo_path"
        return 1
    fi
    
    local result
    result=$("$SCRIPTS_PATH/validate_repo.sh" "$repo_path" 2>&1)
    
    if [ "$result" = "VALID" ]; then
        print_success "Valid git repository: $repo_path"
        return 0
    else
        print_error "Invalid git repository: $repo_path"
        print_info "This directory is not a git repository."
        return 1
    fi
}

# Display commit history
show_commits() {
    local repo_path="$1"
    local commits_raw
    
    print_info "Fetching commit history..."
    
    if ! commits_raw=$("$SCRIPTS_PATH/fetch_commits.sh" "$repo_path" 2>&1); then
        print_error "Failed to fetch commits"
        COMMIT_COUNT=0
        return 1
    fi
    
    # Clear previous commit data
    COMMIT_HASHES=()
    COMMIT_SUBJECTS=()
    
    # Parse and display commits
    echo -e "\n${BOLD}${CYAN}Commit History:${NC}\n"
    
    local count=0
    local in_commit=false
    local hash="" author="" timestamp="" subject=""
    
    while IFS= read -r line; do
        if [[ "$line" == "COMMIT_START" ]]; then
            in_commit=true
            hash="" ; author="" ; timestamp="" ; subject=""
        elif [[ "$line" == "COMMIT_END" ]]; then
            if [ -n "$hash" ]; then
                count=$((count + 1))
                
                # Convert timestamp to readable date
                local date_str
                date_str=$(format_timestamp "$timestamp")
                
                # Display commit
                echo -e "${BOLD}${YELLOW}[$count]${NC} ${GREEN}${hash:0:8}${NC}"
                echo -e "    ${BOLD}Author:${NC} $author"
                echo -e "    ${BOLD}Date:${NC}   $date_str"
                echo -e "    ${BOLD}Msg:${NC}    $subject"
                echo ""
                
                # Store commit info for later selection (using arrays)
                COMMIT_HASHES[$count]="$hash"
                COMMIT_SUBJECTS[$count]="$subject"
            fi
            in_commit=false
        elif [ "$in_commit" = true ]; then
            if [[ "$line" =~ ^HASH:(.+)$ ]]; then
                hash="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^AUTHOR:(.+)$ ]]; then
                author="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^TIMESTAMP:(.+)$ ]]; then
                timestamp="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^SUBJECT:(.+)$ ]]; then
                subject="${BASH_REMATCH[1]}"
            fi
        fi
    done <<< "$commits_raw"
    
    COMMIT_COUNT=$count
}

# Revert to selected commit
revert_to_commit() {
    local repo_path="$1"
    local commit_hash="$2"
    local commit_subject="$3"
    
    print_warning "This will reset the current branch to the selected commit."
    print_warning "All commits after this point will be lost from the current branch."
    echo -e "\n${BOLD}Selected commit:${NC}"
    echo -e "  ${GREEN}${commit_hash:0:8}${NC} - $commit_subject"
    echo ""
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r confirmation
    
    if [ "$confirmation" != "yes" ]; then
        print_info "Revert cancelled."
        return 1
    fi
    
    print_info "Reverting branch..."
    
    local result
    result=$("$SCRIPTS_PATH/revert_branch.sh" "$repo_path" "$commit_hash" 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "Branch successfully reverted to $commit_hash"
        return 0
    else
        print_error "Failed to revert branch"
        echo "$result"
        return 1
    fi
}

# Main menu
show_menu() {
    local repo_path="$1"
    
    while true; do
        show_main_header
        
        if [ -n "$repo_path" ]; then
            print_success "Repository: $repo_path"
        fi
        
        echo -e "${BOLD}Main Menu:${NC}"
        echo -e "  ${CYAN}1)${NC} Select repository"
        echo -e "  ${CYAN}2)${NC} View commit history"
        echo -e "  ${CYAN}3)${NC} Revert branch to commit"
        echo -e "  ${CYAN}4)${NC} Exit"
        echo ""
        echo -n "Choose an option [1-4]: "
        read -r choice
        
        case $choice in
            1)
                echo ""
                local new_path
                new_path=$(get_repository_path)
                echo ""
                if validate_repository "$new_path"; then
                    repo_path="$new_path"
                fi
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            2)
                if [ -z "$repo_path" ]; then
                    echo ""
                    print_error "No repository selected. Please select a repository first."
                    echo ""
                    echo "Press Enter to continue..."
                    read -r
                    continue
                fi
                
                echo ""
                show_commits "$repo_path"
                
                if [ "$COMMIT_COUNT" -gt 0 ]; then
                    print_success "Total commits: $COMMIT_COUNT"
                else
                    print_warning "No commits found"
                fi
                
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            3)
                if [ -z "$repo_path" ]; then
                    echo ""
                    print_error "No repository selected. Please select a repository first."
                    echo ""
                    echo "Press Enter to continue..."
                    read -r
                    continue
                fi
                
                echo ""
                show_commits "$repo_path"
                
                if [ "$COMMIT_COUNT" -eq 0 ]; then
                    print_warning "No commits found"
                    echo ""
                    echo "Press Enter to continue..."
                    read -r
                    continue
                fi
                
                echo ""
                echo -n "Enter commit number to revert to [1-$COMMIT_COUNT] (or 0 to cancel): "
                read -r commit_num
                
                if [ "$commit_num" = "0" ]; then
                    print_info "Cancelled"
                    echo ""
                    echo "Press Enter to continue..."
                    read -r
                    continue
                fi
                
                # Validate input is a number
                if ! [[ "$commit_num" =~ ^[0-9]+$ ]]; then
                    print_error "Invalid input. Please enter a number."
                    echo ""
                    echo "Press Enter to continue..."
                    read -r
                    continue
                fi
                
                if [ "$commit_num" -ge 1 ] && [ "$commit_num" -le "$COMMIT_COUNT" ]; then
                    local selected_hash="${COMMIT_HASHES[$commit_num]}"
                    local selected_subject="${COMMIT_SUBJECTS[$commit_num]}"
                    
                    echo ""
                    revert_to_commit "$repo_path" "$selected_hash" "$selected_subject"
                else
                    print_error "Invalid commit number"
                fi
                
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
            4)
                echo ""
                print_info "Thank you for using GitUtil!"
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid option. Please choose 1-4."
                echo ""
                echo "Press Enter to continue..."
                read -r
                ;;
        esac
    done
}

# Main execution
main() {
    # Check if required scripts exist
    if [ ! -f "$SCRIPTS_PATH/validate_repo.sh" ] || \
       [ ! -f "$SCRIPTS_PATH/fetch_commits.sh" ] || \
       [ ! -f "$SCRIPTS_PATH/revert_branch.sh" ]; then
        echo "Error: Required scripts not found in $SCRIPTS_PATH"
        exit 1
    fi
    
    # If repository path provided as argument, use it
    local initial_repo=""
    if [ -n "$1" ]; then
        initial_repo="$1"
        if validate_repository "$initial_repo"; then
            echo ""
            echo "Press Enter to continue..."
            read -r
        else
            initial_repo=""
            echo ""
            echo "Press Enter to continue..."
            read -r
        fi
    fi
    
    # Show main menu
    show_menu "$initial_repo"
}

# Run main function
main "$@"
