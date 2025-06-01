#!/bin/bash

# Cyberpunk-themed ANSI color codes
NEON_PINK='\033[1;35m'
NEON_CYAN='\033[1;36m'
NEON_GREEN='\033[1;32m'
NEON_RED='\033[1;31m'
DARK_PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to display cyberpunk-themed header
display_header() {
    clear
    echo -e "${NEON_PINK}
    ╔══════════════════════════════════════╗
    ║   NEON GIT: CYBERPUNK REPO MANAGER   ║
    ║   Powered by xAI Neural Networks     ║
    ╚══════════════════════════════════════╝${NC}"
    echo -e "${DARK_PURPLE}>>> Initializing cybernetic repository interface...${NC}\n"
    sleep 0.5
}

# Function to check if git is installed
check_git_installed() {
    if ! command -v git &>/dev/null; then
        echo -e "${NEON_RED}[-] CRITICAL ERROR: Git neural module not detected${NC}"
        echo -e "${DARK_PURPLE}>>> Install Git to interface with this system${NC}"
        exit 1
    fi
    echo -e "${NEON_GREEN}[+] Git module online${NC}"
}

# Function to find all Git repositories
find_git_repos() {
    echo -e "${NEON_CYAN}[*] Scanning cyberspace for Git repositories...${NC}"
    sleep 0.3
    local repo_list=()
    while IFS= read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        repo_list+=("$repo_dir")
    done < <(find / -type d -name ".git" -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" -not -path "/tmp/*" 2>/dev/null)
    for repo in "${repo_list[@]}"; do
        echo -e "${DARK_PURPLE}>>> Located node: $repo${NC}"
    done
    printf '%s\n' "${repo_list[@]}"
}

# Function to display animated loading effect
display_loading() {
    local spinstr='|/-\'
    local i=0
    for ((j=0; j<10; j++)); do
        printf "\r${NEON_CYAN}[%s] Processing...${NC}" "${spinstr:$((i%4)):1}"
        i=$((i+1))
        sleep 0.1
    done
    printf "\r"
}

# Function to perform Git operations with cyberpunk styling
perform_git_operation() {
    local repo_dir=$1
    if [ ! -d "$repo_dir" ]; then
        echo -e "${NEON_RED}[-] ERROR: Repository node $repo_dir offline or corrupted${NC}"
        return 1
    fi

    cd "$repo_dir" || {
        echo -e "${NEON_RED}[-] Failed to interface with $repo_dir${NC}"
        return 1
    }

    display_loading
    echo -e "\n${NEON_PINK}=== Accessing Repository: $(basename "$repo_dir") ===${NC}"
    echo -e "${DARK_PURPLE}>>> Node path: $repo_dir${NC}"

    local git_status staged_changes unstaged_changes branch
    git_status=$(git status --porcelain 2>/dev/null)
    staged_changes=$(echo "$git_status" | grep '^M' | wc -l)
    unstaged_changes=$(echo "$git_status" | grep '^ ' | wc -l)
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    echo -e "\n${NEON_GREEN}=== SYSTEM STATUS ===${NC}"
    echo -e "${NEON_CYAN}  Branch: ${branch}${NC}"
    echo -e "${NEON_CYAN}  Staged Data Packets: ${staged_changes}${NC}"
    echo -e "${NEON_CYAN}  Unstaged Data Packets: ${unstaged_changes}${NC}"

    echo -e "\n${NEON_PINK}=== NEON GIT INTERFACE ===${NC}"
    echo -e "${NEON_CYAN}  [1] Encrypt & Commit Data${NC}"
    echo -e "${NEON_CYAN}  [2] Uplink to Remote Server${NC}"
    echo -e "${NEON_CYAN}  [3] Downlink from Remote Server${NC}"
    echo -e "${NEON_CYAN}  [4] Scan Repository Status${NC}"
    echo -e "${NEON_CYAN}  [5] Disconnect to Main Grid${NC}"
    echo -e "${NEON_CYAN}  [6] Terminate Neural Link${NC}"

    local choice
    echo -e -n "${NEON_PINK}>>> Select operation [1-6]: ${NC}"
    read choice
    case $choice in
        1)
            local commit_msg
            echo -e -n "${NEON_CYAN}>>> Enter commit signature: ${NC}"
            read commit_msg
            if [ -z "$commit_msg" ]; then
                echo -e "${NEON_RED}[-] ERROR: Signature cannot be null${NC}"
            else
                display_loading
                if git add . && git commit -m "$commit_msg"; then
                    echo -e "${NEON_GREEN}[+] Data encrypted and committed${NC}"
                else
                    echo -e "${NEON_RED}[-] Commit operation failed${NC}"
                fi
            fi
            perform_git_operation "$repo_dir"
            ;;
        2)
            display_loading
            if git push origin "$branch"; then
                echo -e "${NEON_GREEN}[+] Uplink to remote server successful${NC}"
            else
                echo -e "${NEON_RED}[-] Uplink failed. Check network or credentials${NC}"
            fi
            perform_git_operation "$repo_dir"
            ;;
        3)
            display_loading
            if git pull origin "$branch"; then
                echo -e "${NEON_GREEN}[+] Downlink from remote server successful${NC}"
            else
                echo -e "${NEON_RED}[-] Downlink failed. Check network or conflicts${NC}"
            fi
            perform_git_operation "$repo_dir"
            ;;
        4)
            display_loading
            echo -e "${NEON_GREEN}=== Detailed System Scan ===${NC}"
            git status
            echo -e "\n${NEON_CYAN}>>> Press Enter to return to interface...${NC}"
            read
            perform_git_operation "$repo_dir"
            ;;
        5)
            echo -e "${NEON_PINK}>>> Disconnecting from $(basename "$repo_dir")${NC}"
            return 0
            ;;
        6)
            echo -e "${NEON_PINK}>>> Terminating neural link to NEON GIT${NC}"
            sleep 0.5
            exit 0
            ;;
        *)
            echo -e "${NEON_RED}[-] Invalid operation code. Select 1-6${NC}"
            perform_git_operation "$repo_dir"
            ;;
    esac
}

# Main script execution
check_git_installed
display_header

# Find all Git repositories
mapfile -t repos < <(find_git_repos)
if [ ${#repos[@]} -eq 0 ]; then
    echo -e "${NEON_RED}[-] No Git repositories detected in cyberspace${NC}"
    exit 1
fi

echo -e "${NEON_GREEN}[+] Located ${#repos[@]} active repository nodes${NC}\n"
sleep 0.5

# Repository selection loop with filter and aligned columns
while true; do
    # Filter selection
    echo -e "${NEON_PINK}=== Filter Repositories ===${NC}"
    echo -e "${NEON_CYAN}  [1] Show all (default)${NC}"
    echo -e "${NEON_CYAN}  [2] Show only with changes${NC}"
    echo -e "${NEON_CYAN}  [3] Show only clean${NC}"
    echo -e -n "${NEON_PINK}>>> Select filter [1-3]: ${NC}"
    read filter_choice
    case $filter_choice in
        2) filter="changes" ;;
        3) filter="clean" ;;
        *) filter="all" ;;
    esac

    # Build displayed repositories based on filter
    displayed_repos=()
    displayed_statuses=()
    for repo in "${repos[@]}"; do
        if [ -d "$repo" ]; then
            cd "$repo" || continue
            status=$(git status --porcelain 2>/dev/null)
            if [ "$filter" = "all" ] || \
               ([ "$filter" = "changes" ] && [ -n "$status" ]) || \
               ([ "$filter" = "clean" ] && [ -z "$status" ]); then
                displayed_repos+=("$repo")
                if [ -z "$status" ]; then
                    displayed_statuses+=("Clean")
                else
                    displayed_statuses+=("Changes")
                fi
            fi
        elif [ "$filter" = "all" ]; then
            displayed_repos+=("$repo")
            displayed_statuses+=("Inaccessible")
        fi
    done

    if [ ${#displayed_repos[@]} -eq 0 ]; then
        echo -e "${NEON_RED}[-] No repositories match the filter${NC}"
        sleep 1
        continue
    fi

    # Calculate maximum lengths for alignment
    max_num_length=5
    max_name_length=10
    for i in "${!displayed_repos[@]}"; do
        num=$((i+1))
        if [ ${#num} -gt $max_num_length ]; then
            max_num_length=${#num}
        fi
        name=$(basename "${displayed_repos[$i]}")
        if [ ${#name} -gt $max_name_length ]; then
            max_name_length=${#name}
        fi
    done

    # Display repository list with aligned columns
    echo -e "\n${NEON_PINK}=== Select a Repository Node ===${NC}"
    printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "No" "Repository" "Status"
    printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "--" "----------" "------"
    for i in "${!displayed_repos[@]}"; do
        name=$(basename "${displayed_repos[$i]}")
        status=${displayed_statuses[$i]}
        if [ "$status" = "Clean" ]; then
            formatted_status="${NEON_GREEN}[Clean]${NC}"
        elif [ "$status" = "Changes" ]; then
            formatted_status="${NEON_RED}[Changes]${NC}"
        else
            formatted_status="${NEON_RED}[Inaccessible]${NC}"
        fi
        printf "%-${max_num_length}s  %-${max_name_length}s  %s\n" "$((i+1))" "$name" "$formatted_status"
    done
    echo -e "$(( ${#displayed_repos[@]}+1 )). Exit"

    # Handle user selection
    echo -e -n "${NEON_PINK}>>> Enter number: ${NC}"
    read choice
    if [ "$choice" == "$(( ${#displayed_repos[@]}+1 ))" ]; then
        echo -e "${NEON_PINK}>>> Terminating NEON GIT interface${NC}"
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#displayed_repos[@]}" ]; then
        selected_repo=${displayed_repos[$((choice-1))]}
        if [ -d "$selected_repo" ]; then
            perform_git_operation "$selected_repo"
        else
            echo -e "${NEON_RED}[-] Repository node inaccessible: $selected_repo${NC}"
            sleep 1
        fi
    else
        echo -e "${NEON_RED}[-] Invalid selection${NC}"
        sleep 1
    fi
done