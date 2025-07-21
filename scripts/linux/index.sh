#!/bin/bash

GITCOMPASS_VERSION="1.0.0"

# Dependency check
for cmd in git awk sed grep xargs; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed. Please install it and try again."
        exit 1
    fi
done

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art for GitCompass
print_logo() {
    echo -e "${CYAN}"
    echo "   ____ _ _    ____                                 "
    echo "  / ___(_) |_ / ___|___  _ __ ___  ___  __ _ _ __  "
    echo " | |  _| | __| |   / _ \\| '__/ _ \\/ __|/ _\` | '_ \\ "
    echo " | |_| | | |_| |__| (_) | | |  __/ (__| (_| | | | |"
    echo "  \\____|_|\\\__|\\\____\\___/|_|  \\___|\\___|\\__,_|_| |_|"
    echo -e "${NC}"
    echo -e "${YELLOW}Welcome to GitCompass v${GITCOMPASS_VERSION} - Your Git Repository Navigator!${NC}\n"
}

# Function to find all Git repositories
find_git_repos() {
    # Search only under $HOME for speed
    find "$HOME" -type d -name ".git" -not -path "$HOME/.cache/*" 2>/dev/null | while read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        echo "$repo_dir"
    done
}

# Function to get a friendly repo name
get_repo_name() {
    local repo_dir="$1"
    local repo_name
    repo_name=$(cd "$repo_dir" && git config --get remote.origin.url 2>/dev/null | sed -E 's#.*/([^/]+)\.git$#\1#')
    if [ -z "$repo_name" ]; then
        repo_name=$(basename "$repo_dir")
    fi
    echo "$repo_name"
}

# Function to get repo status indicator
get_repo_status_indicator() {
    local repo_dir="$1"
    local indicator="${GREEN}🟢${NC}"
    # Check for uncommitted changes
    if [ -n "$(cd "$repo_dir" && git status --porcelain 2>/dev/null)" ]; then
        indicator="${YELLOW}🟡${NC}"
    fi
    # Check for unpushed commits (ahead of remote)
    local branch_status
    branch_status=$(cd "$repo_dir" && git status -sb 2>/dev/null)
    if echo "$branch_status" | grep -q '\[ahead '; then
        if [ "$indicator" = "${YELLOW}🟡${NC}" ]; then
            indicator="${YELLOW}🟡${NC}${ORANGE}🟠${NC}"
        else
            indicator="${ORANGE}🟠${NC}"
        fi
    fi
    echo -e "$indicator"
}

# Function to perform Git operations
perform_git_operation() {
    local repo_dir=$1
    while true; do
        cd "$repo_dir" || {
            echo -e "${RED}Failed to access $repo_dir${NC}"
            return 1
        }
        local repo_name
        repo_name=$(get_repo_name "$repo_dir")
        echo -e "${BLUE}Current repository: $repo_name ($repo_dir)${NC}"
        echo -e "${YELLOW}Tip:${NC} Type the number for your action, or 'back' to return."
        echo -e "${GREEN}1.${NC} Add all changed files and commit"
        echo -e "${GREEN}2.${NC} Push your code"
        echo -e "${GREEN}3.${NC} Check Repo status"
        echo -e "${GREEN}4.${NC} Return to main menu"
        echo -e "${GREEN}5.${NC} Pull latest changes"
        echo -e "${GREEN}6.${NC} View recent commit log"
        echo -e "${GREEN}7.${NC} Help/About"
        echo -e "${GREEN}8.${NC} Stash changes (save work temporarily)"
        echo -e "${GREEN}9.${NC} Pop latest stash (restore stashed work)"
        echo -e "${GREEN}10.${NC} Advanced log view (filter by author/branch)"
        echo -e "${YELLOW}Type 'back' or press Enter to return to the previous menu.${NC}"
        read -p "Select an option (1-10): " choice
        if [[ -z "$choice" || "$choice" =~ ^[Bb][Aa][Cc][Kk]$ ]]; then
            break
        fi
        case $choice in
        1)
            echo -e "${YELLOW}Commit changes${NC}"
            read -p "Generate commit message automatically? (y/n): " gen_choice
            if [[ "$gen_choice" =~ ^[Yy]$ ]]; then
                changed_files=$(git status --porcelain | awk '{print $2}' | xargs)
                if [ -z "$changed_files" ]; then
                    echo -e "${RED}No changes to commit.${NC}"
                    read -p "Press Enter to return to menu..."
                    continue
                fi
                commit_msg="Update files: $changed_files"
                echo -e "${CYAN}Generated commit message:${NC} $commit_msg"
            else
                read -p "Enter commit message: " commit_msg
            fi
            if git add . && git commit -m "$commit_msg"; then
                echo -e "${GREEN}✅ Changes committed successfully.${NC}"
            else
                echo -e "${RED}❌ Commit failed. Please check for errors above.${NC}"
                read -p "Press Enter to return to menu..."
            fi
            ;;
        2)
            echo -e "${YELLOW}Available branches:${NC}"
            mapfile -t branches < <(git branch --format='%(refname:short)')
            for i in "${!branches[@]}"; do
                echo -e "${GREEN}$((i + 1)).${NC} ${branches[$i]}"
            done
            if [ -n "${default_branch:-}" ]; then
                echo -e "${CYAN}Default branch is set to '${default_branch}'.${NC}"
            fi
            read -p "Select a branch to push (1-${#branches[@]}), or press Enter to use default: " branch_choice
            if [[ -z "$branch_choice" && -n "${default_branch:-}" ]]; then
                selected_branch="$default_branch"
            elif [[ $branch_choice -ge 1 && $branch_choice -le ${#branches[@]} ]]; then
                selected_branch="${branches[$((branch_choice - 1))]}"
            elif [[ -z "$branch_choice" ]]; then
                echo -e "${YELLOW}Push cancelled.${NC}"
                continue
            else
                echo -e "${RED}Invalid branch selection. Please try again.${NC}"
                continue
            fi
            if [ -n "$selected_branch" ]; then
                if git push origin "$selected_branch"; then
                    echo -e "${GREEN}✅ Pushed to remote branch '$selected_branch'.${NC}"
                else
                    echo -e "${RED}❌ Push failed. Please check for errors above.${NC}"
                    read -p "Press Enter to return to menu..."
                fi
            fi
            ;;
        3)
            if ! git status; then
                echo -e "${RED}❌ Failed to get status. Please check for errors above.${NC}"
                read -p "Press Enter to return to menu..."
            fi
            ;;
        4)
            break
            ;;
        5)
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            branch_to_pull="${default_branch:-$current_branch}"
            echo -e "${YELLOW}Pulling latest changes for branch '${branch_to_pull}'...${NC}"
            if git pull origin "$branch_to_pull"; then
                echo -e "${GREEN}✅ Pulled latest changes.${NC}"
            else
                echo -e "${RED}❌ Pull failed. Please check for errors above.${NC}"
                read -p "Press Enter to return to menu..."
            fi
            ;;
        6)
            echo -e "${YELLOW}Recent commit log:${NC}"
            if ! git --no-pager log --oneline --graph --decorate -n 10; then
                echo -e "${RED}❌ Failed to show git log. Please check for errors above.${NC}"
            fi
            read -p "Press Enter to return to menu..."
            ;;
        7)
            echo -e "${CYAN}GitCompass v${GITCOMPASS_VERSION} - Your Git Repository Navigator${NC}"
            echo -e "${YELLOW}Features:${NC}"
            echo "- Scan and manage all your Git repositories from one place."
            echo "- See status indicators for uncommitted and unpushed changes."
            echo "- Add/commit, push, pull, view status, and see recent commit log."
            echo "- User-friendly, menu-driven interface."
            echo -e "\n${YELLOW}Status Legend:${NC} ${GREEN}🟢 Clean${NC}  ${YELLOW}🟡 Uncommitted changes${NC}  ${ORANGE}🟠 Unpushed commits${NC}"
            echo -e "\n${CYAN}Created by Goal651. Enjoy hacking!${NC}"
            read -p "Press Enter to return to menu..."
            ;;
        8)
            if git stash; then
                echo -e "${GREEN}✅ Changes stashed successfully.${NC}"
            else
                echo -e "${RED}❌ Failed to stash changes. Please check for errors above.${NC}"
            fi
            read -p "Press Enter to return to menu..."
            ;;
        9)
            if git stash pop; then
                echo -e "${GREEN}✅ Latest stash applied successfully.${NC}"
            else
                echo -e "${RED}❌ Failed to pop stash. Please check for errors above.${NC}"
            fi
            read -p "Press Enter to return to menu..."
            ;;
        10)
            echo -e "${YELLOW}Advanced log view${NC}"
            read -p "Filter by author (leave blank for all): " log_author
            read -p "Filter by branch (leave blank for current): " log_branch
            log_cmd=(git --no-pager log --pretty=format:'%C(yellow)%h%Creset %C(cyan)%ad%Creset %C(green)%an%Creset %s' --date=short -n 20)
            if [ -n "$log_author" ]; then
                log_cmd+=(--author="$log_author")
            fi
            if [ -n "$log_branch" ]; then
                log_cmd+=("$log_branch")
            fi
            echo -e "${CYAN}Hash      Date       Author               Message${NC}"
            echo -e "${CYAN}-------------------------------------------------------------${NC}"
            if ! "${log_cmd[@]}"; then
                echo -e "${RED}❌ Failed to show advanced log. Please check for errors above.${NC}"
            fi
            echo -e "${CYAN}-------------------------------------------------------------${NC}"
            read -p "Press Enter to return to menu..."
            ;;
        *)
            echo -e "${RED}Invalid option. Please enter a number from 1 to 10, or 'back'.${NC}"
            ;;
        esac
        echo
    done
}

main(){
    while true; do
        clear
        print_logo
        echo -e "${YELLOW}Tip:${NC} Use numbers or letters for menu options. Press Enter to repeat the menu."
        echo -e "${YELLOW}You can type 'back' at any prompt to return to the previous menu.${NC}"
        echo -e "${YELLOW}Scanning for Git repositories...${NC}"
        repos=($(find_git_repos))
        if [ ${#repos[@]} -eq 0 ]; then
            echo -e "${RED}No Git repositories found in $HOME.${NC}"
            read -p "Enter a directory to scan (or leave blank to retry $HOME): " scan_dir
            if [ -n "$scan_dir" ]; then
                export HOME="$scan_dir"
                continue
            else
                continue
            fi
        fi
        # Legend
        echo -e "${CYAN}Status Legend:${NC} ${GREEN}🟢 Clean${NC}  ${YELLOW}🟡 Uncommitted changes${NC}  ${ORANGE}🟠 Unpushed commits${NC}"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
        printf "${BLUE}%-4s %-30s %-40s %s${NC}\n" "No." "Repository" "Path" "Status"
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
        # Before displaying repos, filter if filter_term is set
        filtered_repos=()
        if [ -n "$filter_term" ]; then
            for repo in "${repos[@]}"; do
                repo_name=$(get_repo_name "$repo")
                if [[ "$repo_name" == *"$filter_term"* || "$repo" == *"$filter_term"* ]]; then
                    filtered_repos+=("$repo")
                fi
            done
        else
            filtered_repos=("${repos[@]}")
        fi
        # Use filtered_repos instead of repos in the display and selection
        for i in "${!filtered_repos[@]}"; do
            repo_name=$(get_repo_name "${filtered_repos[$i]}")
            status_indicator=$(get_repo_status_indicator "${filtered_repos[$i]}")
            repo_path="${filtered_repos[$i]}"
            if [ ${#repo_path} -gt 38 ]; then
                repo_path="...${repo_path: -35}"
            fi
            printf "${GREEN}%-4s${NC} \e[1m%-30s\e[0m %-40s %s\n" "$((i + 1))." "$repo_name" "$repo_path" "$status_indicator"
        done
        echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}0.${NC} Rescan repositories"
        echo -e "${GREEN}B.${NC} Batch Status: Show details for all repositories"
        echo -e "${GREEN}C.${NC} Clone a new repository"
        echo -e "${GREEN}D.${NC} Delete a repository"
        echo -e "${GREEN}S.${NC} Search/filter repositories"
        echo -e "${GREEN}T.${NC} Settings/Configuration"
        echo -e "${GREEN}E.${NC} Export repository list/statuses"
        echo -e "${GREEN}I.${NC} Import repository list/statuses"
        read -p "Select a repository (1-${#filtered_repos[@]}), 0 to rescan, B for batch status, C to clone, D to delete, S to search, T for settings, E to export, or I to import: " repo_choice
        if [[ "$repo_choice" == "0" ]]; then
            filter_term=""
            continue
        elif [[ "$repo_choice" =~ ^[Tt]$ ]]; then
            # Settings menu
            config_file="$HOME/.gitcompassrc"
            # Load settings
            [ -f "$config_file" ] && source "$config_file"
            while true; do
                clear
                echo -e "${CYAN}GitCompass Settings${NC}"
                echo -e "1. Set default branch (current: ${default_branch:-none})"
                echo -e "2. Toggle color output (current: ${color_output:-on})"
                echo -e "3. Return to main menu"
                read -p "Select an option (1-3): " set_choice
                case $set_choice in
                    1)
                        read -p "Enter default branch name (leave blank to unset): " new_branch
                        if [ -n "$new_branch" ]; then
                            default_branch="$new_branch"
                        else
                            unset default_branch
                        fi
                        ;;
                    2)
                        if [ "${color_output:-on}" = "on" ]; then
                            color_output="off"
                        else
                            color_output="on"
                        fi
                        ;;
                    3)
                        # Save settings
                        echo "default_branch=\"${default_branch:-}\"" > "$config_file"
                        echo "color_output=\"${color_output:-on}\"" >> "$config_file"
                        break
                        ;;
                    *)
                        echo "Invalid option."
                        ;;
                esac
                sleep 1
            done
            continue
        elif [[ "$repo_choice" =~ ^[Bb]$ ]]; then
            clear
            print_logo
            echo -e "${YELLOW}Batch Status: All Repositories${NC}"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            printf "${BLUE}%-4s %-30s %-40s %-25s %s${NC}\n" "No." "Repository" "Path" "Status" "Message"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            for i in "${!repos[@]}"; do
                repo_name=$(get_repo_name "${repos[$i]}")
                status_indicator=$(get_repo_status_indicator "${repos[$i]}")
                repo_path="${repos[$i]}"
                if [ ${#repo_path} -gt 38 ]; then
                    repo_path="...${repo_path: -35}"
                fi
                # Determine status message
                msg="Clean"
                cd "${repos[$i]}"
                if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                    msg="Uncommitted changes"
                fi
                branch_status=$(git status -sb 2>/dev/null)
                if echo "$branch_status" | grep -q '\[ahead '; then
                    if [ "$msg" = "Uncommitted changes" ]; then
                        msg="Uncommitted & unpushed"
                    else
                        msg="Unpushed commits"
                    fi
                fi
                printf "${GREEN}%-4s${NC} \e[1m%-30s\e[0m %-40s %-25s %s\n" "$((i + 1))." "$repo_name" "$repo_path" "$status_indicator" "$msg"
            done
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            read -p "Press Enter to return to the main menu..."
            continue
        elif [[ "$repo_choice" =~ ^[Cc]$ ]]; then
            echo -e "${YELLOW}Clone a new repository${NC}"
            read -p "Enter the git repository URL: " clone_url
            read -p "Enter the destination directory (or leave blank for default): " clone_dir
            if [ -z "$clone_url" ]; then
                echo -e "${RED}No URL provided. Aborting clone.${NC}"
                read -p "Press Enter to return to the main menu..."
                continue
            fi
            if [ -z "$clone_dir" ]; then
                if git clone "$clone_url"; then
                    echo -e "${GREEN}Repository cloned successfully.${NC}"
                else
                    echo -e "${RED}Failed to clone repository. Please check for errors above.${NC}"
                fi
            else
                if git clone "$clone_url" "$clone_dir"; then
                    echo -e "${GREEN}Repository cloned successfully to $clone_dir.${NC}"
                else
                    echo -e "${RED}Failed to clone repository. Please check for errors above.${NC}"
                fi
            fi
            read -p "Press Enter to return to the main menu..."
            continue
        elif [[ "$repo_choice" =~ ^[Dd]$ ]]; then
            echo -e "${RED}Delete a repository${NC}"
            read -p "Enter the number of the repository to delete (1-${#filtered_repos[@]}), or 'back' to cancel: " del_num
            if [[ -z "$del_num" || "$del_num" =~ ^[Bb][Aa][Cc][Kk]$ ]]; then
                echo -e "${YELLOW}Deletion cancelled.${NC}"
                read -p "Press Enter to return to the main menu..."
                continue
            fi
            if ! [[ "$del_num" =~ ^[0-9]+$ ]] || [ "$del_num" -lt 1 ] || [ "$del_num" -gt ${#filtered_repos[@]} ]; then
                echo -e "${RED}Invalid repository number.${NC}"
                read -p "Press Enter to return to the main menu..."
                continue
            fi
            repo_to_delete="${filtered_repos[$((del_num - 1))]}"
            repo_name=$(get_repo_name "$repo_to_delete")
            echo -e "${RED}Are you sure you want to delete '$repo_name' at $repo_to_delete?${NC}"
            read -p "Type 'yes' to confirm: " confirm
            if [ "$confirm" = "yes" ]; then
                read -p "Type 'delete' to permanently remove this repository: " confirm2
                if [ "$confirm2" = "delete" ]; then
                    if rm -rf "$repo_to_delete"; then
                        echo -e "${GREEN}✅ Repository deleted successfully.${NC}"
                    else
                        echo -e "${RED}❌ Failed to delete repository. Please check for errors above.${NC}"
                    fi
                else
                    echo -e "${YELLOW}Deletion cancelled.${NC}"
                fi
            else
                echo -e "${YELLOW}Deletion cancelled.${NC}"
            fi
            read -p "Press Enter to return to the main menu..."
            continue
        elif [[ "$repo_choice" =~ ^[Ss]$ ]]; then
            read -p "Enter search term (name or path, leave blank to clear filter): " filter_term
            continue
        elif [[ "$repo_choice" =~ ^[Ee]$ ]]; then
            export_file="$HOME/gitcompass_export.txt"
            echo -e "${YELLOW}Exporting repository list and statuses to $export_file...${NC}"
            {
                for repo in "${repos[@]}"; do
                    repo_name=$(get_repo_name "$repo")
                    status_msg="Clean"
                    cd "$repo"
                    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                        status_msg="Uncommitted changes"
                    fi
                    branch_status=$(git status -sb 2>/dev/null)
                    if echo "$branch_status" | grep -q '\[ahead '; then
                        if [ "$status_msg" = "Uncommitted changes" ]; then
                            status_msg="Uncommitted & unpushed"
                        else
                            status_msg="Unpushed commits"
                        fi
                    fi
                    echo -e "$repo_name|$repo|$status_msg"
                done
            } > "$export_file"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Export successful!${NC}"
            else
                echo -e "${RED}Export failed.${NC}"
            fi
            read -p "Press Enter to return to the main menu..."
            continue
        elif [[ "$repo_choice" =~ ^[Ii]$ ]]; then
            import_file="$HOME/gitcompass_export.txt"
            if [ ! -f "$import_file" ]; then
                echo -e "${RED}No export file found at $import_file.${NC}"
                read -p "Press Enter to return to the main menu..."
                continue
            fi
            echo -e "${YELLOW}Imported repository list and statuses:${NC}"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            printf "${BLUE}%-4s %-30s %-40s %-25s${NC}\n" "No." "Repository" "Path" "Status"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            n=1
            while IFS='|' read -r repo_name repo_path status_msg; do
                if [ -n "$repo_name" ]; then
                    if [ ${#repo_path} -gt 38 ]; then
                        repo_path="...${repo_path: -35}"
                    fi
                    printf "${GREEN}%-4s${NC} \e[1m%-30s\e[0m %-40s %-25s\n" "$n." "$repo_name" "$repo_path" "$status_msg"
                    n=$((n+1))
                fi
            done < "$import_file"
            echo -e "${CYAN}───────────────────────────────────────────────────────────────────────────────${NC}"
            read -p "Press Enter to return to the main menu..."
            continue
        elif [[ $repo_choice -ge 1 && $repo_choice -le ${#filtered_repos[@]} ]]; then
            perform_git_operation "${filtered_repos[$((repo_choice - 1))]}"
            continue
        else
            echo -e "${RED}Invalid selection.${NC}"
            read -p "Press Enter to continue..."
        fi
    done
}

# At the top, after color codes, add logic to disable color if color_output=off
[ -f "$HOME/.gitcompassrc" ] && source "$HOME/.gitcompassrc"
if [ "${color_output:-on}" = "off" ]; then
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    ORANGE=''
    NC=''
fi
main