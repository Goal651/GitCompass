#!/bin/bash

# Function to find all Git repositories
find_git_repos() {
    echo "Scanning for Git repositories..."
    find / -type d -name ".git" -not -path "/proc/*" -not -path "/sys/*" 2>/dev/null | while read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        echo "$repo_dir"
    done
}

# Function to perform Git operations
perform_git_operation() {
    local repo_dir=$1
    cd "$repo_dir" || {
        echo "Failed to access $repo_dir"
        return 1
    }
    echo "Current repository: $repo_dir"
    echo "1. Add all and commit"
    echo "2. Push to remote"
    echo "3. Check status"
    echo "4. Exit"
    read -p "Select an option (1-4): " choice

    case $choice in
    1)
        read -p "Enter commit message: " commit_msg
        git add . && git commit -m "$commit_msg" && echo "Changes committed."
        ;;
    2)
        git push origin main && echo "Pushed to remote." || echo "Push failed."
        ;;
    3)
        git status
        ;;
    4)
        exit 0
        ;;
    *)
        echo "Invalid option."
        ;;
    esac
}

# Main script
echo "Git Repository Manager"
repos=($(find_git_repos))
if [ ${#repos[@]} -eq 0 ]; then
    echo "No Git repositories found."
    exit 1
fi

echo "Found ${#repos[@]} repositories:"
for i in "${!repos[@]}"; do
    echo "$((i + 1)). ${repos[$i]}"
done

read -p "Select a repository (1-${#repos[@]}): " repo_choice
if [[ $repo_choice -ge 1 && $repo_choice -le ${#repos[@]} ]]; then
    perform_git_operation "${repos[$((repo_choice - 1))]}"
else
    echo "Invalid selection."
    exit 1
fi
