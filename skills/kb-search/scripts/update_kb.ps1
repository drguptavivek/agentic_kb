#!/usr/bin/env pwsh
# Update the KB to latest version
# Works for both submodule and direct repo setups

param(
    [string]$SubmodulePath = "",
    [switch]$SyncUpstream
)

$ErrorActionPreference = "Stop"

function Detect-KbPath {
    $scriptRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    if ((Test-Path (Join-Path $scriptRoot "knowledge")) -and (Test-Path (Join-Path $scriptRoot "scripts/search_typesense.py"))) {
        return $scriptRoot
    }

    if ((Test-Path "agentic_kb/knowledge") -and (Test-Path "agentic_kb/scripts/search_typesense.py")) {
        return "agentic_kb"
    }

    if ((Test-Path "knowledge") -and (Test-Path "scripts/search_typesense.py")) {
        return "."
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($SubmodulePath)) {
    $SubmodulePath = Detect-KbPath
    if ([string]::IsNullOrWhiteSpace($SubmodulePath)) {
        Write-Host "Error: Could not auto-detect KB path."
        Write-Host "Pass SubmodulePath pointing to KB root (contains knowledge/ and scripts/)."
        exit 1
    }
}

Write-Host "Updating KB: $SubmodulePath"
Write-Host ""

if (-not (Test-Path -Path $SubmodulePath -PathType Container)) {
    Write-Host "Error: KB not found at $SubmodulePath"
    Write-Host ""
    Write-Host "This repository doesn't have the KB set up yet."
    Write-Host "Run: scripts/setup_kb.sh or scripts/setup_kb.ps1"
    exit 1
}

Push-Location $SubmodulePath
try {
    if (-not (Test-Path ".git")) {
        Write-Host "Error: $SubmodulePath is not a git repository"
        exit 1
    }

    $hasUpstream = ((git remote) | Select-String -Pattern "^upstream$" -Quiet)
    $originUrl = git remote get-url origin

    Write-Host "Current setup:"
    Write-Host "  Origin: $originUrl"

    if ($hasUpstream) {
        $upstreamUrl = git remote get-url upstream
        Write-Host "  Upstream: $upstreamUrl"
        Write-Host "  -> Detected fork configuration"
        Write-Host ""

        Write-Host "Syncing with upstream..."
        git fetch upstream

        $upstreamChanges = (git rev-list HEAD..upstream/main --count 2>$null)
        if (-not $upstreamChanges) {
            $upstreamChanges = "0"
        }

        if ([int]$upstreamChanges -eq 0) {
            Write-Host "Already in sync with upstream"
        } else {
            Write-Host "Found $upstreamChanges new commit(s) from upstream"
            Write-Host "Merging upstream changes..."
            git merge upstream/main --no-edit
            Write-Host "Pushing to your fork..."
            git push origin main
            Write-Host "Synced with upstream and pushed to your fork"
        }
    } else {
        Write-Host "  -> Direct repository (no upstream configured)"
        Write-Host ""
        Write-Host "Pulling latest changes from origin..."

        git pull origin main
        if ($LASTEXITCODE -ne 0) {
            git pull origin master
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Pull failed, continuing."
            }
        }
    }
} finally {
    Pop-Location
}

if (Test-Path -Path (Join-Path $SubmodulePath ".git") -PathType Leaf) {
    Write-Host ""
    Write-Host "Updating parent project..."

    git diff --quiet -- $SubmodulePath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Parent project is already up to date"
    } else {
        Write-Host "Committing submodule pointer update..."
        git add $SubmodulePath
        git commit -m "Update: $SubmodulePath submodule to latest"
    }
}

Write-Host ""
Write-Host "KB is now up to date!"

if ((git -C $SubmodulePath remote | Select-String -Pattern "^upstream$" -Quiet)) {
    Write-Host ""
    Write-Host "Your fork is synced with upstream."
    Write-Host "You can add your own knowledge and it will persist across updates."
}
