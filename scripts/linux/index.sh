#!/bin/bash

# Function to find all Git repositories
find_git_repos() {
    echo -e "\033[1;34mScanning for Git repositories...\033[0m"
    find / -type d -name ".git" -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | while read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        echo "$repo_dir"
    done
}

# Function to perform Git operations
perform_git_operation() {
    local repo_dir=$1
    cd "$repo_dir" || {
        echo -e "\033[1;31mFailed to access $repo_dir\033[0m"
        return 1
    }
    echo -e "\033[1;34mCurrent repository: $repo_dir\033[0m"

    # Get the status of the repository
    git_status=$(git status --porcelain)

    # Parse the status output to get the number of staged and unstaged changes
    staged_changes=$(echo "$git_status" | grep '^M' | wc -l)
    unstaged_changes=$(echo "$git_status" | grep '^ ' | wc -l)

    # Print the status information
    echo -e "\033[1;32mStatus:\033[0m"
    echo -e "  \033[1;36mStaged changes: $staged_changes\033[0m"
    echo -e "  \033[1;36mUnstaged changes: $unstaged_changes\033[0m"

    # Print the menu
    echo -e "\033[1;34mOptions:\033[0m"
    echo -e "  \033[1;36m1. Add all and commit\033[0m"
    echo -e "  \033[1;36m2. Push to remote\033[0m"
    echo -e "  \033[1;36m3. Check status\033[0m"
    echo -e "  \033[1;36m4. Exit\033[0m"

    # Read the user's choice
    read -p "Select an option (1-4): " choice

    # Perform the chosen action
    case $choice in
    1)
        read -p "Enter commit message: " commit_msg
        git add . && git commit -m "$commit_msg" && echo -e "\033[1;32mChanges committed.\033[0m"
        ;;
    2)
        git push origin main && echo -e "\033[1;32mPushed to remote.\033[0m" || echo -e "\033[1;31mPush failed.\033[0m"
        ;;
    3)
        git status
        ;;
    4)
        exit 0
        ;;
    *)
        echo -e "\033[1;31mInvalid option.\033[0m"
        ;;
    esac
}

# Main script
echo -e "\033[1;34m _______
|       |
|  Git  |
|  Repo  |
|  Manager|
|_______|\033[0m"

repos=($(find_git_repos))
if [ ${#repos[@]} -eq 0 ]; then
    echo -e "\033[1;31mNo Git repositories found.\033[0m"
    exit 1
fi

while true; do
    echo -e "\033[1;32mFound ${#repos[@]} repositories:\033[0m"
    for i in "${!repos[@]}"; do
        echo -e "  \033[1;36m$((i + 1)). ${repos[$i]}\033[0m"
    done

    read -p "Select a repository (1-${#repos[@]}): " repo_choice
    if [[ $repo_choice -ge 1 && $repo_choice -le ${#repos[@]} ]]; then
        perform_git_operation "${repos[$((repo_choice - 1))]}"
    else
        echo -e "\033[1;31mInvalid selection.\033[0m"
        exit 1
    fi
done