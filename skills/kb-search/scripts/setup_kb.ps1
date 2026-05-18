#!/usr/bin/env pwsh
# Initial setup for agentic_kb knowledge base

param(
    [string]$SubmodulePath = "agentic_kb",
    [switch]$ReadOnly,
    [switch]$Default,
    [switch]$Central,
    [string]$ForkUrl = ""
)

$ErrorActionPreference = "Stop"

$UpstreamRepo = "https://github.com/drguptavivek/agentic_kb.git"
$CentralPath = if ($env:AGENTIC_KB_PATH) { $env:AGENTIC_KB_PATH } else { Join-Path $HOME ".agentic_kb" }
if ($Default) {
    $ForkUrl = $UpstreamRepo
}

Write-Host "Setting up agentic_kb knowledge base"
Write-Host ""

if ($Central) {
    $cloneUrl = if ([string]::IsNullOrWhiteSpace($ForkUrl)) { $UpstreamRepo } else { $ForkUrl }

    Write-Host "Setting up centralized KB at: $CentralPath"
    Write-Host ""

    if ((Test-Path $CentralPath) -and -not (Test-Path (Join-Path $CentralPath ".git"))) {
        Write-Host "Error: $CentralPath exists but is not a git repository"
        exit 1
    }

    if (Test-Path (Join-Path $CentralPath ".git")) {
        Write-Host "Central KB already exists"
        Write-Host "Pulling latest changes..."
        git -C $CentralPath pull --ff-only origin main
        if ($LASTEXITCODE -ne 0) {
            git -C $CentralPath pull --ff-only origin master
        }
    } else {
        Write-Host "Cloning KB..."
        git clone $cloneUrl $CentralPath
    }

    Write-Host ""
    Write-Host "Central KB is ready at: $CentralPath"
    Write-Host ""
    Write-Host "Use from any project:"
    Write-Host "  $CentralPath/scripts/smart_search.sh `"your query`""
    Write-Host "  $CentralPath/scripts/update_kb.sh"
    Write-Host ""
    Write-Host "Optional environment override:"
    Write-Host "  `$env:AGENTIC_KB_PATH = `"$CentralPath`""
    exit 0
}

if (Test-Path -Path $SubmodulePath -PathType Container) {
    Write-Host "KB already exists at: $SubmodulePath"
    Write-Host ""

    if (Test-Path -Path (Join-Path $SubmodulePath ".git")) {
        Push-Location $SubmodulePath
        try {
            $currentRemote = git remote get-url origin 2>$null
            Write-Host "Current remote: $currentRemote"
            Write-Host ""

            $upstreamRemote = git remote get-url upstream 2>$null

            if ([string]::IsNullOrWhiteSpace($upstreamRemote) -and $currentRemote -ne $UpstreamRepo) {
                Write-Host "Adding upstream remote for syncing with original KB..."
                git remote add upstream $UpstreamRepo
                Write-Host "Upstream remote added: $UpstreamRepo"
            } elseif (-not [string]::IsNullOrWhiteSpace($upstreamRemote)) {
                Write-Host "Upstream remote already configured: $upstreamRemote"
            }
        } finally {
            Pop-Location
        }
        exit 0
    }
}

Write-Host "This will set up the agentic_kb knowledge base in your project."
Write-Host ""

if ($ReadOnly) {
    Write-Host "Setting up READ-ONLY access (you won't be able to push changes)"
    Write-Host ""
    git submodule add $UpstreamRepo $SubmodulePath
    git add .gitmodules $SubmodulePath
    Write-Host ""
    Write-Host "KB added as read-only submodule"
    Write-Host "Next step: git commit -m `"Add: agentic_kb submodule (read-only)`""
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ForkUrl)) {
    Write-Host "Error: Please provide -ForkUrl <URL>, -Default, or -ReadOnly"
    Write-Host "Create a fork first:"
    Write-Host "  Web: https://github.com/drguptavivek/agentic_kb"
    Write-Host "  CLI: gh repo fork drguptavivek/agentic_kb --clone=false"
    exit 1
}

Write-Host "Adding KB submodule..."
git submodule add $ForkUrl $SubmodulePath

if ($ForkUrl -ne $UpstreamRepo) {
    Write-Host "Setting up upstream remote..."
    Push-Location $SubmodulePath
    try {
        git remote add upstream $UpstreamRepo
    } finally {
        Pop-Location
    }
}

git add .gitmodules $SubmodulePath
Write-Host ""
Write-Host "Setup complete."
Write-Host "KB path: $SubmodulePath"
