# Windows PowerShell Reference

Use this file only when the user is on Windows or explicitly asks for PowerShell. Normal macOS/Linux usage should stay in `SKILL.md` and `setup-reference.md`.

## Search

```powershell
agentic_kb/scripts/smart_search.ps1 "query"
agentic_kb/scripts/smart_search.ps1 "query" -Filter "domain:Search"
~/.agentic_kb/scripts/smart_search.ps1 "query"
scripts/smart_search.ps1 "query"
```

## Update

Ask before updating from git:

```powershell
agentic_kb/scripts/update_kb.ps1
~/.agentic_kb/scripts/update_kb.ps1
scripts/update_kb.ps1
```

## Centralized Setup

```powershell
scripts/setup_kb.ps1 -Central
scripts/setup_kb.ps1 -Central -ForkUrl <USER_KB_REPO_URL>
$env:AGENTIC_KB_PATH = "C:\path\to\agentic_kb"; scripts/setup_kb.ps1 -Central
```

## Submodule Setup

```powershell
scripts/setup_kb.ps1 -ForkUrl <USER_KB_REPO_URL>
scripts/setup_kb.ps1 -Default
scripts/setup_kb.ps1 -ReadOnly
```

## UV Cache

```powershell
$env:UV_CACHE_DIR = (Join-Path (Resolve-Path .).Path ".uv-cache")
New-Item -ItemType Directory -Path $env:UV_CACHE_DIR -Force | Out-Null
```

