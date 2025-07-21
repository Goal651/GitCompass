# GitCompass PowerShell - Cross-platform Git Repository Manager
$GITCOMPASS_VERSION = "1.0.0"
$ConfigFile = "$env:USERPROFILE\.gitcompassrc.ps1"

function Show-Logo {
    Write-Host "" -ForegroundColor Cyan
    Write-Host "   ____ _ _    ____                                 " -ForegroundColor Cyan
    Write-Host "  / ___(_) |_ / ___|___  _ __ ___  ___  __ _ _ __  " -ForegroundColor Cyan
    Write-Host " | |  _| | __| |   / _ \\| '__/ _ \\ / __|/ _\` | '_ \\ " -ForegroundColor Cyan
    Write-Host " | |_| | | |_| |__| (_) | | |  __/ (__| (_| | | | |" -ForegroundColor Cyan
    Write-Host "  \\____|_|\\__|\\____\\___/|_|  \\___|\\___|\\__,_|_| |_|" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor Cyan
    Write-Host "GitCompass v$GITCOMPASS_VERSION - Your Git Repository Navigator!" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
}

function Check-Dependencies {
    $deps = @('git', 'Select-String', 'Out-Null', 'Write-Host', 'Get-ChildItem', 'Read-Host')
    foreach ($dep in $deps) {
        if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
            Write-Host "Error: Required command '$dep' is not available. Please install it and try again." -ForegroundColor Red
            exit 1
        }
    }
}

function Load-Config {
    if (Test-Path $ConfigFile) {
        . $ConfigFile
    }
}

function Save-Config {
    "`$DefaultBranch = '$DefaultBranch'" | Set-Content $ConfigFile
    Add-Content $ConfigFile "`$ColorOutput = '$ColorOutput'"
}

function Get-RepoName {
    param($RepoPath)
    $remote = git -C $RepoPath config --get remote.origin.url 2>$null
    if ($remote) {
        if ($remote -match "/([^/]+)\.git$") { return $Matches[1] }
        else { return (Split-Path $RepoPath -Leaf) }
    } else {
        return (Split-Path $RepoPath -Leaf)
    }
}

function Find-GitRepos {
    param($RootDir)
    Write-Host "Scanning for Git repositories in $RootDir..." -ForegroundColor Yellow
    $repos = Get-ChildItem -Path $RootDir -Recurse -Directory -Hidden -Filter ".git" -ErrorAction SilentlyContinue | ForEach-Object { $_.Parent.FullName } | Sort-Object -Unique
    return $repos
}

function Get-RepoStatusIndicator {
    param($RepoPath)
    $status = git -C $RepoPath status --porcelain
    $branch = git -C $RepoPath status -sb
    $indicator = "🟢"
    if ($status) { $indicator = "🟡" }
    if ($branch -match '\[ahead ') {
        if ($indicator -eq "🟡") { $indicator = "🟡🟠" } else { $indicator = "🟠" }
    }
    return $indicator
}

function Main-Menu {
    Load-Config
    $RootDir = $env:USERPROFILE
    while ($true) {
        Clear-Host
        Show-Logo
        Write-Host "Tip: Use numbers or letters for menu options. Press Enter to repeat the menu." -ForegroundColor Yellow
        Write-Host "You can type 'back' at any prompt to return to the previous menu." -ForegroundColor Yellow
        $repos = Find-GitRepos $RootDir
        if (-not $repos -or $repos.Count -eq 0) {
            Write-Host "No Git repositories found in $RootDir." -ForegroundColor Red
            $scanDir = Read-Host "Enter a directory to scan (or leave blank to retry $RootDir)"
            if ($scanDir) { $RootDir = $scanDir; continue } else { continue }
        }
        Write-Host "Status Legend: 🟢 Clean  🟡 Uncommitted changes  🟠 Unpushed commits" -ForegroundColor Cyan
        Write-Host ("{0,-4} {1,-30} {2,-40} {3}" -f 'No.', 'Repository', 'Path', 'Status') -ForegroundColor Blue
        for ($i = 0; $i -lt $repos.Count; $i++) {
            $repoName = Get-RepoName $repos[$i]
            $status = Get-RepoStatusIndicator $repos[$i]
            $repoPath = $repos[$i]
            if ($repoPath.Length -gt 38) { $repoPath = "..." + $repoPath.Substring($repoPath.Length-35) }
            Write-Host ("{0,-4} {1,-30} {2,-40} {3}" -f ($i+1), $repoName, $repoPath, $status) -ForegroundColor Green
        }
        Write-Host "0. Rescan repositories" -ForegroundColor Green
        Write-Host "B. Batch Status: Show details for all repositories" -ForegroundColor Green
        Write-Host "C. Clone a new repository" -ForegroundColor Green
        Write-Host "D. Delete a repository" -ForegroundColor Green
        Write-Host "S. Search/filter repositories" -ForegroundColor Green
        Write-Host "T. Settings/Configuration" -ForegroundColor Green
        Write-Host "E. Export repository list/statuses" -ForegroundColor Green
        Write-Host "I. Import repository list/statuses" -ForegroundColor Green
        $choice = Read-Host "Select a repository (1-$($repos.Count)), 0 to rescan, B for batch status, C to clone, D to delete, S to search, T for settings, E to export, or I to import"
        if ($choice -eq '0') { continue }
        elseif ($choice -match '^[Bb]$') { Batch-Status $repos; continue }
        elseif ($choice -match '^[Cc]$') { Clone-Repo; continue }
        elseif ($choice -match '^[Dd]$') { Delete-Repo $repos; continue }
        elseif ($choice -match '^[Ss]$') { Search-Filter $repos; continue }
        elseif ($choice -match '^[Tt]$') { Settings-Menu; continue }
        elseif ($choice -match '^[Ee]$') { Export-RepoList $repos; continue }
        elseif ($choice -match '^[Ii]$') { Import-RepoList; continue }
        elseif ($choice -match '^[0-9]+$' -and $choice -ge 1 -and $choice -le $repos.Count) {
            Repo-Menu $repos[$choice-1]
            continue
        } else {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

# (Other functions: Batch-Status, Clone-Repo, Delete-Repo, Search-Filter, Settings-Menu, Export-RepoList, Import-RepoList, Repo-Menu, etc. would be implemented here, following the Linux version's logic and user-friendliness.)

Check-Dependencies
Main-Menu