#!/usr/bin/env pwsh
# Smart KB search: Try Typesense first, fallback to FAISS if no good results

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Query,
    [string]$Filter = "",
    [double]$MinScore = 0.7,
    [string]$KbPath = ""
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

if ([string]::IsNullOrWhiteSpace($KbPath)) {
    $KbPath = Detect-KbPath
    if ([string]::IsNullOrWhiteSpace($KbPath)) {
        Write-Host "Error: Could not auto-detect KB path."
        Write-Host "Pass -KbPath to the KB root (contains knowledge/ and scripts/)."
        exit 1
    }
}

Write-Host "Searching KB for: $Query"
Write-Host ""
Write-Host "Trying Typesense (fast full-text search)..."

$tempResults = [System.IO.Path]::GetTempFileName()
try {
    $typesenseArgs = @("run", "--with", "typesense", "python", (Join-Path $KbPath "scripts/search_typesense.py"), $Query)
    if (-not [string]::IsNullOrWhiteSpace($Filter)) {
        $typesenseArgs += @("--filter", $Filter)
    }

    $typesenseOutput = & uv @typesenseArgs 2>&1
    $typesenseExitCode = $LASTEXITCODE
    $typesenseOutput | Set-Content -Path $tempResults

    if ($typesenseExitCode -eq 0) {
        $resultCount = (Get-Content -Path $tempResults | Measure-Object -Line).Lines
        if ($resultCount -gt 5) {
            Write-Host "Found results in Typesense:"
            Write-Host ""
            Get-Content -Path $tempResults
            exit 0
        }
        Write-Host "Typesense returned few/no results"
    } else {
        Write-Host "Typesense search failed (server might not be running)"
    }
} finally {
    Remove-Item -Path $tempResults -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Falling back to FAISS (semantic vector search)..."
Write-Host ""

Push-Location $KbPath
try {
    & uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py $Query --min-score $MinScore
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
