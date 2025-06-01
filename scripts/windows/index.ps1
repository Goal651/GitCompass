# Cyberpunk-themed color definitions for PowerShell
$NEON_PINK = "Magenta"
$NEON_CYAN = "Cyan"
$NEON_GREEN = "Green"
$NEON_RED = "Red"
$DARK_PURPLE = "DarkMagenta"
$NC = "White"

# Function to display cyberpunk-themed header
function Display-Header {
    Clear-Host
    Write-Host -ForegroundColor $NEON_PINK @"
    ╔══════════════════════════════════════╗
    ║   NEON GIT: CYBERPUNK REPO MANAGER   ║
    ║   Powered by xAI Neural Networks     ║
    ╚══════════════════════════════════════╝
"@
    Write-Host -ForegroundColor $DARK_PURPLE ">>> Initializing cybernetic repository interface...`n"
    Start-Sleep -Milliseconds 500
}

# Function to check if git is installed
function Check-GitInstalled {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor $NEON_RED "[-] CRITICAL ERROR: Git neural module not detected"
        Write-Host -ForegroundColor $DARK_PURPLE ">>> Install Git to interface with this system"
        exit 1
    }
    Write-Host -ForegroundColor $NEON_GREEN "[+] Git module online"
}

# Function to find all Git repositories
function Find-GitRepos {
    Write-Host -ForegroundColor $NEON_CYAN "[*] Scanning cyberspace for Git repositories..."
    Start-Sleep -Milliseconds 300
    $repo_list = @()
    # Search in user home directory and subdirectories
    $search_paths = @(
        "$env:USERPROFILE",
        "$env:USERPROFILE\Documents\PROJECTS",
        "$env:USERPROFILE\.oh-my-zsh",
        "$env:USERPROFILE\.config",
        "$env:USERPROFILE\Arduino"
    )
    foreach ($path in $search_paths) {
        if (Test-Path $path) {
            $git_dirs = Get-ChildItem -Path $path -Directory -Recurse -Include ".git" -ErrorAction SilentlyContinue
            foreach ($git_dir in $git_dirs) {
                $repo_dir = $git_dir.Parent.FullName
                Write-Host -ForegroundColor $DARK_PURPLE ">>> Located node: $repo_dir"
                $repo_list += $repo_dir
            }
        }
    }
    # Output the repository list for further processing
    $repo_list
}

# Function to display animated loading effect
function Display-Loading {
    $spinstr = '|/-\'
    for ($i = 0; $i -lt 10; $i++) {
        $char = $spinstr[$i % 4]
        Write-Host -NoNewline -ForegroundColor $NEON_CYAN "[$char] Processing..."
        Start-Sleep -Milliseconds 100
        Write-Host -NoNewline "`r"
    }
}

# Function to perform Git operations with cyberpunk styling
function Perform-GitOperation {
    param (
        [string]$RepoDir
    )
    if (-not (Test-Path $RepoDir)) {
        Write-Host -ForegroundColor $NEON_RED "[-] ERROR: Repository node $RepoDir offline or corrupted"
        return 1
    }

    Set-Location $RepoDir -ErrorAction SilentlyContinue
    if ($?) {
        Display-Loading
        $repo_name = Split-Path $RepoDir -Leaf
        Write-Host -ForegroundColor $NEON_PINK "`n=== Accessing Repository: $repo_name ==="
        Write-Host -ForegroundColor $DARK_PURPLE ">>> Node path: $RepoDir"

        # Retrieve repository status
        $git_status = Invoke-Expression "git status --porcelain" | Out-String
        $staged_changes = ($git_status -split "`n" | Where-Object { $_ -match "^M" } | Measure-Object).Count
        $unstaged_changes = ($git_status -split "`n" | Where-Object { $_ -match "^ " } | Measure-Object).Count
        $branch = (Invoke-Expression "git rev-parse --abbrev-ref HEAD" | Out-String).Trim()
        if (-not $branch) { $branch = "unknown" }

        Write-Host -ForegroundColor $NEON_GREEN "`n=== SYSTEM STATUS ==="
        Write-Host -ForegroundColor $NEON_CYAN "  Branch: $branch"
        Write-Host -ForegroundColor $NEON_CYAN "  Staged Data Packets: $staged_changes"
        Write-Host -ForegroundColor $NEON_CYAN "  Unstaged Data Packets: $unstaged_changes"

        Write-Host -ForegroundColor $NEON_PINK "`n=== NEON GIT INTERFACE ==="
        Write-Host -ForegroundColor $NEON_CYAN "  [1] Encrypt & Commit Data"
        Write-Host -ForegroundColor $NEON_CYAN "  [2] Uplink to Remote Server"
        Write-Host -ForegroundColor $NEON_CYAN "  [3] Downlink from Remote Server"
        Write-Host -ForegroundColor $NEON_CYAN "  [4] Scan Repository Status"
        Write-Host -ForegroundColor $NEON_CYAN "  [5] Disconnect to Main Grid"
        Write-Host -ForegroundColor $NEON_CYAN "  [6] Terminate Neural Link"

        Write-Host -NoNewline -ForegroundColor $NEON_PINK ">>> Select operation [1-6]: "
        $choice = Read-Host
        switch ($choice) {
            "1" {
                Write-Host -NoNewline -ForegroundColor $NEON_CYAN ">>> Enter commit signature: "
                $commit_msg = Read-Host
                if (-not $commit_msg) {
                    Write-Host -ForegroundColor $NEON_RED "[-] ERROR: Signature cannot be null"
                }
                else {
                    Display-Loading
                    $add_result = Invoke-Expression "git add ." 2>&1
                    $commit_result = Invoke-Expression "git commit -m `"$commit_msg`"" 2>&1
                    if ($?) {
                        Write-Host -ForegroundColor $NEON_GREEN "[+] Data encrypted and committed"
                    }
                    else {
                        Write-Host -ForegroundColor $NEON_RED "[-] Commit operation failed: $commit_result"
                    }
                }
                Perform-GitOperation -RepoDir $RepoDir
            }
            "2" {
                Display-Loading
                $push_result = Invoke-Expression "git push origin $branch" 2>&1
                if ($?) {
                    Write-Host -ForegroundColor $NEON_GREEN "[+] Uplink to remote server successful"
                }
                else {
                    Write-Host -ForegroundColor $NEON_RED "[-] Uplink failed. Check network or credentials: $push_result"
                }
                Perform-GitOperation -RepoDir $RepoDir
            }
            "3" {
                Display-Loading
                $pull_result = Invoke-Expression "git pull origin $branch" 2>&1
                if ($?) {
                    Write-Host -ForegroundColor $NEON_GREEN "[+] Downlink from remote server successful"
                }
                else {
                    Write-Host -ForegroundColor $NEON_RED "[-] Downlink failed. Check network or conflicts: $pull_result"
                }
                Perform-GitOperation -RepoDir $RepoDir
            }
            "4" {
                Display-Loading
                Write-Host -ForegroundColor $NEON_GREEN "=== Detailed System Scan ==="
                $status = Invoke-Expression "git status" | Out-String
                Write-Host $status
                Write-Host -ForegroundColor $NEON_CYAN "`n>>> Press Enter to return to interface..."
                Read-Host
                Perform-GitOperation -RepoDir $RepoDir
            }
            "5" {
                Write-Host -ForegroundColor $NEON_PINK ">>> Disconnecting from $repo_name"
                return 0
            }
            "6" {
                Write-Host -ForegroundColor $NEON_PINK ">>> Terminating neural link to NEON GIT"
                Start-Sleep -Milliseconds 500
                exit 0
            }
            default {
                Write-Host -ForegroundColor $NEON_RED "[-] Invalid operation code. Select 1-6"
                Perform-GitOperation -RepoDir $RepoDir
            }
        }
    }
    else {
        Write-Host -ForegroundColor $NEON_RED "[-] Failed to interface with $RepoDir"
        return 1
    }
}

# Main script execution
Check-GitInstalled
Display-Header

# Find all Git repositories
$repos = Find-GitRepos
if ($repos.Count -eq 0) {
    Write-Host -ForegroundColor $NEON_RED "[-] No Git repositories detected in cyberspace"
    exit 1
}

Write-Host -ForegroundColor $NEON_GREEN "[+] Located $($repos.Count) active repository nodes`n"
Start-Sleep -Milliseconds 500

# Repository selection loop with filter and aligned columns
while ($true) {
    # Filter selection
    Write-Host -ForegroundColor $NEON_PINK "=== Filter Repositories ==="
    Write-Host -ForegroundColor $NEON_CYAN "  [1] Show all (default)"
    Write-Host -ForegroundColor $NEON_CYAN "  [2] Show only with changes"
    Write-Host -ForegroundColor $NEON_CYAN "  [3] Show only clean"
    Write-Host -NoNewline -ForegroundColor $NEON_PINK ">>> Select filter [1-3]: "
    $filter_choice = Read-Host
    $filter = switch ($filter_choice) {
        "2" { "changes" }
        "3" { "clean" }
        default { "all" }
    }

    # Build displayed repositories based on filter
    $displayed_repos = @()
    $displayed_statuses = @()
    foreach ($repo in $repos) {
        if (Test-Path $repo) {
            Set-Location $repo -ErrorAction SilentlyContinue
            if ($?) {
                $status = Invoke-Expression "git status --porcelain" | Out-String
                if ($filter -eq "all" -or
                    ($filter -eq "changes" -and $status.Trim()) -or
                    ($filter -eq "clean" -and -not $status.Trim())) {
                    $displayed_repos += $repo
                    $displayed_statuses += if ($status.Trim()) { "Changes" } else { "Clean" }
                }
            }
        }
        elseif ($filter -eq "all") {
            $displayed_repos += $repo
            $displayed_statuses += "Inaccessible"
        }
    }

    if ($displayed_repos.Count -eq 0) {
        Write-Host -ForegroundColor $NEON_RED "[-] No repositories match the filter"
        Start-Sleep -Seconds 1
        continue
    }

    # Calculate maximum lengths for alignment
    $max_num_length = 5
    $max_name_length = 10
    for ($i = 0; $i -lt $displayed_repos.Count; $i++) {
        $num = ($i + 1).ToString()
        if ($num.Length -gt $max_num_length) {
            $max_num_length = $num.Length
        }
        $name = Split-Path $displayed_repos[$i] -Leaf
        if ($name.Length -gt $max_name_length) {
            $max_name_length = $name.Length
        }
    }

    # Display repository list with aligned columns
    Write-Host -ForegroundColor $NEON_PINK "`n=== Select a Repository Node ==="
    Write-Host -ForegroundColor $NC ("{0,-$max_num_length}  {1,-$max_name_length}  Status" -f "No", "Repository")
    Write-Host -ForegroundColor $NC ("{0,-$max_num_length}  {1,-$max_name_length}  ------" -f "--", "----------")
    for ($i = 0; $i -lt $displayed_repos.Count; $i++) {
        $name = Split-Path $displayed_repos[$i] -Leaf
        $status = $displayed_statuses[$i]
        $color = if ($status -eq "Clean") { $NEON_GREEN } elseif ($status -eq "Changes") { $NEON_RED } else { $NEON_RED }
        Write-Host -ForegroundColor $NC ("{0,-$max_num_length}  {1,-$max_name_length}  " -f ($i + 1), $name) -NoNewline
        Write-Host -ForegroundColor $color "[$status]"
    }
    Write-Host "$($displayed_repos.Count + 1). Exit"

    # Handle user selection
    Write-Host -NoNewline -ForegroundColor $NEON_PINK ">>> Enter number: "
    $choice = Read-Host
    if ($choice -eq ($displayed_repos.Count + 1)) {
        Write-Host -ForegroundColor $NEON_PINK ">>> Terminating NEON GIT interface"
        exit 0
    }
    elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $displayed_repos.Count) {
        $selected_repo = $displayed_repos[$choice - 1]
        if (Test-Path $selected_repo) {
            Perform-GitOperation -RepoDir $selected_repo
        }
        else {
            Write-Host -ForegroundColor $NEON_RED "[-] Repository node inaccessible: $selected_repo"
            Start-Sleep -Seconds 1
        }
    }
    else {
        Write-Host -ForegroundColor $NEON_RED "[-] Invalid selection"
        Start-Sleep -Seconds 1
    }
}