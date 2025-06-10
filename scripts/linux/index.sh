#!/bin/bash

# ANSI color codes
NEON_PINK='\033[1;35m'
NEON_CYAN='\033[1;36m'
NEON_GREEN='\033[1;32m'
NEON_RED='\033[1;31m'
DARK_PURPLE='\033[0;35m'
NC='\033[0;37m'

# Display header
display_header() {
    clear
    echo -e "${NEON_PINK}
    ╔══════════════════════════════════════╗
    ║   NEON GIT: CYBERPUNK REPO MANAGER   ║
    ║   Powered by xAI Neural Networks     ║
    ╚══════════════════════════════════════╝${NC}\n${DARK_PURPLE}>>> Initializing cybernetic repository interface...${NC}\n"
    sleep 0.5
}

# Check if git is installed
check_git_installed() {
    command -v git &>/dev/null || {
        echo -e "${NEON_RED}[-] CRITICAL ERROR: Git neural module not detected${NC}\n${DARK_PURPLE}>>> Install Git to interface with this system${NC}"
        exit 1
    }
    echo -e "${NEON_GREEN}[+] Git module online${NC}"
}

# Display loading animation
display_loading() {
    local spinStr='|/-\'
    for ((i = 0; i < 10; i++)); do
        printf "\r${NEON_CYAN}[${spinStr:$((i % 4)):1}] Processing...${NC}"
        sleep 0.05  # Faster animation for snappier feel
    done
    printf "\r"
}

# Check repository status
check_repo_status() {
    local repo_dir="$1"
    cd "$repo_dir" || return 1
    local git_status
    git_status=$(git status --porcelain 2>/dev/null) || return 1
    local staged_changes
    staged_changes=$(echo "$git_status" | grep -c '^M')  # Simplified counting
    local unstaged_changes
    unstaged_changes=$(echo "$git_status" | grep -c '^ ')  # Simplified counting
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo "$staged_changes|$unstaged_changes|$branch"
}

# Find Git repositories
find_git_repos() {
    echo -e "${NEON_CYAN}[*] Scanning cyberspace for Git repositories...${NC}"
    sleep 0.3
    local repo_list=()
    # Scan only user's home directory, exclude inaccessible dirs
    while IFS= read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        if [ -r "$repo_dir" ]; then
            repo_list+=("$repo_dir")
            echo -e "${DARK_PURPLE}>>> Located node: $repo_dir${NC}"
        else
            echo -e "${DARK_PURPLE}>>> Skipping inaccessible node: $repo_dir${NC}"
        fi
    done < <(find "$HOME" -type d -name ".git" -not -path "*/.git/*" 2>/dev/null)
    printf '%s\n' "${repo_list[@]}"
}

# Perform Git operations
perform_git_operation() {
    local repo_dir="$1"
    [ -d "$repo_dir" ] && [ -r "$repo_dir" ] || {
        echo -e "${NEON_RED}[-] ERROR: Repository node $repo_dir offline or inaccessible${NC}"
        return 1
    }

    cd "$repo_dir" || {
        echo -e "${NEON_RED}[-] Failed to interface with $repo_dir${NC}"
        return 1
    }

    display_loading
    echo -e "\n${NEON_PINK}=== Accessing Repository: $(basename "$repo_dir") ===${NC}\n${DARK_PURPLE}>>> Node path: $repo_dir${NC}"

    # Get repo status
    local status
    status=$(check_repo_status "$repo_dir") || {
        echo -e "${NEON_RED}[-] ERROR: Failed to scan repository status${NC}"
        return 1
    }
    IFS='|' read -r staged_changes unstaged_changes branch <<< "$status"
    echo -e "\n${NEON_GREEN}=== SYSTEM STATUS ===${NC}\n${NEON_CYAN}  Branch: $branch\n  Staged Data Packets: $staged_changes\n  Unstaged Data Packets: $unstaged_changes${NC}"

    echo -e "\n${NEON_PINK}=== NEON GIT INTERFACE ===${NC}"
    echo -e "${NEON_CYAN}  [1] Encrypt & Commit Data\n  [2] Uplink to Remote Server\n  [3] Downlink from Remote Server\n  [4] Scan Repository Status\n  [5] Switch Neural Branch\n  [6] View Commit Logs\n  [7] Disconnect to Main Grid\n  [8] Terminate Neural Link${NC}"

    echo -e -n "${NEON_PINK}>>> Select operation [1-8]: ${NC}"
    read -r choice
    case $choice in
    1)
        echo -e -n "${NEON_CYAN}>>> Enter commit signature: ${NC}"
        read -r commit_msg
        if [ -z "$commit_msg" ]; then
            echo -e "${NEON_RED}[-] ERROR: Signature cannot be null${NC}"
        else
            display_loading
            if git add . && git commit -m "$commit_msg" 2>/dev/null; then
                echo -e "${NEON_GREEN}[+] Data encrypted and committed${NC}"
            else
                echo -e "${NEON_RED}[-] Commit operation failed. Check repository state.${NC}"
            fi
        fi
        perform_git_operation "$repo_dir"
        ;;
    2)
        echo -e -n "${NEON_CYAN}>>> Confirm branch to uplink [$branch]: ${NC}"
        read -r push_branch
        push_branch=${push_branch:-$branch}  # Default to current branch
        display_loading
        if git push origin "$push_branch" 2>/dev/null; then
            echo -e "${NEON_GREEN}[+] Uplink to remote server successful${NC}"
        else
            echo -e "${NEON_RED}[-] Uplink failed. Check network, credentials, or branch.${NC}"
        fi
        perform_git_operation "$repo_dir"
        ;;
    3)
        echo -e -n "${NEON_CYAN}>>> Confirm branch to downlink [$branch]: ${NC}"
        read -r pull_branch
        pull_branch=${pull_branch:-$branch}  # Default to current branch
        display_loading
        if git fetch origin && git pull origin "$pull_branch" 2>/dev/null; then
            echo -e "${NEON_GREEN}[+] Downlink from remote server successful${NC}"
        else
            echo -e "${NEON_RED}[-] Downlink failed. Check network, conflicts, or branch.${NC}"
        fi
        perform_git_operation "$repo_dir"
        ;;
    4)
        display_loading
        echo -e "${NEON_GREEN}=== Detailed System Scan ===${NC}"
        git status
        echo -e "\n${NEON_CYAN}>>> Press Enter to return to interface...${NC}"
        read -r
        perform_git_operation "$repo_dir"
        ;;
    5)
        echo -e "${NEON_CYAN}=== Available Neural Branches ===${NC}"
        git branch --list | while read -r branch_line; do
            echo -e "${NEON_CYAN}  $branch_line${NC}"
        done
        echo -e -n "${NEON_CYAN}>>> Enter branch to switch to: ${NC}"
        read -r new_branch
        if [ -n "$new_branch" ] && git checkout "$new_branch" 2>/dev/null; then
            echo -e "${NEON_GREEN}[+] Switched to neural branch $new_branch${NC}"
        else
            echo -e "${NEON_RED}[-] Failed to switch to branch $new_branch${NC}"
        fi
        perform_git_operation "$repo_dir"
        ;;
    6)
        display_loading
        echo -e "${NEON_GREEN}=== Recent Commit Logs ===${NC}"
        git log --oneline --max-count=10 2>/dev/null || echo -e "${NEON_RED}[-] Failed to retrieve logs${NC}"
        echo -e "\n${NEON_CYAN}>>> Press Enter to return to interface...${NC}"
        read -r
        perform_git_operation "$repo_dir"
        ;;
    7)
        echo -e "${NEON_PINK}>>> Disconnecting from $(basename "$repo_dir")${NC}"
        return 0
        ;;
    8)
        echo -e "${NEON_PINK}>>> Terminating neural link to NEON GIT${NC}"
        sleep 0.5
        exit 0
        ;;
    *)
        echo -e "${NEON_RED}[-] Invalid operation code. Select 1-8${NC}"
        perform_git_operation "$repo_dir"
        ;;
    esac
}

# Main execution
check_git_installed
display_header


# Find repositories
mapfile -t repos < <(find_git_repos)
[ ${#repos[@]} -eq 0 ] && {
    echo -e "${NEON_RED}[-] No Git repositories detected in cyberspace${NC}"
    exit 1
}
echo -e "${NEON_GREEN}[+] Located ${#repos[@]} active repository nodes${NC}\n"
sleep 0.5

# Repository selection loop
while true; do
    echo -e "${NEON_PINK}=== Filter Repositories ===${NC}\n${NEON_CYAN}  [1] Show all (default)\n  [2] Show only with changes\n  [3] Show only clean${NC}"
    echo -e -n "${NEON_PINK}>>> Select filter [1-3]: ${NC}"
    read -r filter_choice
    case $filter_choice in
    2) filter="changes" ;;
    3) filter="clean" ;;
    *) filter="all" ;;
    esac

    displayed_repos=()
    displayed_statuses=()
    for repo in "${repos[@]}"; do
        if [ -d "$repo" ] && [ -r "$repo" ]; then
            status=$(check_repo_status "$repo")
            IFS='|' read -r staged_changes unstaged_changes _ <<< "$status"
            if [ "$filter" = "all" ] || ([ "$filter" = "changes" ] && [ $((staged_changes + unstaged_changes)) -gt 0 ]) || ([ "$filter" = "clean" ] && [ $((staged_changes + unstaged_changes)) -eq 0 ]); then
                displayed_repos+=("$repo")
                displayed_statuses+=($([ $((staged_changes + unstaged_changes)) -eq 0 ] && echo "Clean" || echo "Changes"))
            fi
        elif [ "$filter" = "all" ]; then
            displayed_repos+=("$repo")
            displayed_statuses+=("Inaccessible")
        fi
    done

    [ ${#displayed_repos[@]} -eq 0 ] && {
        echo -e "${NEON_RED}[-] No repositories match the filter${NC}"
        sleep 1
        continue
    }

    # Dynamic column width for better formatting
    max_num_length=5
    max_name_length=10
    for i in "${!displayed_repos[@]}"; do
        num=$((i + 1))
        [ ${#num} -gt $max_num_length ] && max_num_length=${#num}
        name=$(basename "${displayed_repos[$i]}")
        [ ${#name} -gt $max_name_length ] && max_name_length=${#name}
    done

    echo -e "\n${NEON_PINK}=== Select a Repository Node ===${NC}"
    printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "No" "Repository" "Status"
    printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "--" "----------" "------"
    for i in "${!displayed_repos[@]}"; do
        name=$(basename "${displayed_repos[$i]}")
        status=${displayed_statuses[$i]}
        formatted_status=$([ "$status" = "Clean" ] && echo "${NEON_GREEN}[Clean]" || [ "$status" = "Changes" ] && echo "${NEON_RED}[Changes]" || echo "${NEON_RED}[Inaccessible]${NC}")
        printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "$((i + 1))" "$name" "$formatted_status"
    done
    echo -e "$((${#displayed_repos[@]} + 1)). Exit"

    echo -e -n "${NEON_PINK}>>> Enter number: ${NC}"
    read -r choice
    if [ "$choice" == "$((${#displayed_repos[@]} + 1))" ]; then
        echo -e "${NEON_PINK}>>> Terminating NEON GIT interface${NC}"
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#displayed_repos[@]}" ]; then
        selected_repo=${displayed_repos[$((choice - 1))]}
        perform_git_operation "$selected_repo"
    else
        echo -e "${NEON_RED}[-] Invalid selection${NC}"
        sleep 1
    fi
done