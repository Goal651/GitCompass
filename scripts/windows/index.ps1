# Function to find all Git repositories
function Find-GitRepos {
    Write-Host "Scanning for Git repositories..."
    $repos = Get-ChildItem -Path C:\ -Recurse -Directory -Hidden -Filter ".git" -ErrorAction SilentlyContinue | ForEach-Object { $_.Parent.FullName }
    if ($repos.Count -eq 0) {
        Write-Host "No Git repositories found."
        exit 1
    }
    return $repos
}

# Function to perform Git operations
function Perform-GitOperation {
    param (
        [string]$RepoPath
    )
    Set-Location -Path $RepoPath -ErrorAction Stop
    Write-Host "Current repository: $RepoPath"
    Write-Host "1. Add all and commit"
    Write-Host "2. Push to remote"
    Write-Host "3. Check status"
    Write-Host "4. Exit"
    $choice = Read-Host "Select an option (1-4)"

    switch ($choice) {
        1 {
            $commitMsg = Read-Host "Enter commit message"
            git add . | Out-Null
            git commit -m $commitMsg | Out-Null
            Write-Host "Changes committed."
        }
        2 {
            git push origin main | Out-Null
            if ($?) { Write-Host "Pushed to remote." } else { Write-Host "Push failed." }
        }
        3 {
            git status
        }
        4 {
            exit 0
        }
        default {
            Write-Host "Invalid option."
        }
    }
}

# Main script
Write-Host "Git Repository Manager"
$repos = Find-GitRepos
Write-Host "Found $($repos.Count) repositories:"
for ($i = 0; $i -lt $repos.Count; $i++) {
    Write-Host "$($i+1). $($repos[$i])"
}

$repoChoice = Read-Host "Select a repository (1-$($repos.Count))"
if ($repoChoice -ge 1 -and $repoChoice -le $repos.Count) {
    Perform-GitOperation -RepoPath $repos[$repoChoice-1]
} else {
    Write-Host "Invalid selection."
    exit 1
}