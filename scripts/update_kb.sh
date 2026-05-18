#!/bin/bash
# Update the KB to latest version
# Works for submodule, direct repo, and centralized ~/.agentic_kb setups
#
# Usage: ./update_kb.sh [submodule_path] [--sync-upstream]
#
# Arguments:
#   submodule_path   - Path to the KB root (optional; auto-detected)
#   --sync-upstream  - Force sync with upstream (for forks)

set -euo pipefail

SUBMODULE_PATH=""
SYNC_UPSTREAM=false

# Parse args/flags
for arg in "$@"; do
    case "$arg" in
        --sync-upstream)
            SYNC_UPSTREAM=true
            ;;
        *)
            if [ -z "$SUBMODULE_PATH" ]; then
                SUBMODULE_PATH="$arg"
            fi
            ;;
    esac
done

detect_kb_path() {
    local script_dir script_root
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    script_root="$(cd "$script_dir/.." && pwd)"

    # Explicit environment override for centralized installs.
    if [ -n "${AGENTIC_KB_PATH:-}" ] && [ -d "$AGENTIC_KB_PATH/knowledge" ] && [ -f "$AGENTIC_KB_PATH/scripts/search_typesense.py" ]; then
        echo "$AGENTIC_KB_PATH"
        return 0
    fi

    # If running from inside the KB repo (submodule or direct clone)
    if [ -d "$script_root/knowledge" ] && [ -f "$script_root/scripts/search_typesense.py" ]; then
        echo "$script_root"
        return 0
    fi

    # If running from a parent repo (submodule layout)
    if [ -d "agentic_kb/knowledge" ] && [ -f "agentic_kb/scripts/search_typesense.py" ]; then
        echo "agentic_kb"
        return 0
    fi

    # If running from the KB repo root directly
    if [ -d "knowledge" ] && [ -f "scripts/search_typesense.py" ]; then
        echo "."
        return 0
    fi

    # Centralized per-user clone shared by multiple projects.
    if [ -d "$HOME/.agentic_kb/knowledge" ] && [ -f "$HOME/.agentic_kb/scripts/search_typesense.py" ]; then
        echo "$HOME/.agentic_kb"
        return 0
    fi

    return 1
}

if [ -z "$SUBMODULE_PATH" ]; then
    if ! SUBMODULE_PATH="$(detect_kb_path)"; then
        echo "❌ Error: Could not auto-detect KB path."
        echo "   Pass submodule_path pointing to KB root (contains knowledge/ and scripts/)."
        exit 1
    fi
fi

echo "🔄 Updating KB: $SUBMODULE_PATH"
echo ""

# Check if KB path exists
if [ ! -d "$SUBMODULE_PATH" ]; then
    echo "❌ Error: KB not found at $SUBMODULE_PATH"
    echo ""
    echo "   This repository doesn't have the KB set up yet."
    echo "   Run: scripts/setup_kb.sh"
    exit 1
fi

# Navigate to submodule
cd "$SUBMODULE_PATH"

# Check if it's a git repository (in submodules, .git is a file, not a directory)
if [ ! -e ".git" ]; then
    echo "❌ Error: $SUBMODULE_PATH is not a git repository"
    cd - > /dev/null
    exit 1
fi

# Detect if this is a fork (has upstream remote)
HAS_UPSTREAM=$(git remote | grep -c "^upstream$" || true)
ORIGIN_URL=$(git remote get-url origin)

echo "📍 Current setup:"
echo "   Origin: $ORIGIN_URL"

if [ "$HAS_UPSTREAM" -gt 0 ]; then
    UPSTREAM_URL=$(git remote get-url upstream)
    echo "   Upstream: $UPSTREAM_URL"
    echo "   → Detected fork configuration"
    echo ""

    # For forks, sync with upstream
    echo "🔄 Syncing with upstream..."
    git fetch upstream

    # Check if there are upstream changes
    UPSTREAM_CHANGES=$(git rev-list HEAD..upstream/main --count 2>/dev/null || echo "0")

    if [ "$UPSTREAM_CHANGES" -eq 0 ]; then
        echo "✅ Already in sync with upstream"
    else
        echo "📥 Found $UPSTREAM_CHANGES new commit(s) from upstream"
        echo "   Merging upstream changes..."

        # Merge upstream changes
        git merge upstream/main --no-edit

        # Push to user's fork
        echo "📤 Pushing to your fork..."
        git push origin main

        echo "✅ Synced with upstream and pushed to your fork"
    fi
else
    echo "   → Direct repository (no upstream configured)"
    echo ""

    # For direct repos, just pull from origin
    echo "📥 Pulling latest changes from origin..."
    git pull origin main || git pull origin master || echo "⚠️  Pull failed, trying submodule update..."
fi

cd - > /dev/null

# Update parent project's submodule pointer only when it is a relative submodule path
if [ -f "$SUBMODULE_PATH/.git" ] && [[ "$SUBMODULE_PATH" != /* ]]; then
    echo ""
    echo "💾 Updating parent project..."

    # Check if there are changes to the submodule pointer
    if git diff --quiet "$SUBMODULE_PATH"; then
        echo "✅ Parent project is already up to date"
    else
        echo "📝 Committing submodule pointer update..."
        git add "$SUBMODULE_PATH"
        git commit -m "Update: $SUBMODULE_PATH submodule to latest"

        echo "✅ KB updated successfully"
        echo ""
        echo "Next step: git push"
    fi
fi

echo ""
echo "📚 KB is now up to date!"

# Show helpful info for forks
if [ "$HAS_UPSTREAM" -gt 0 ]; then
    echo ""
    echo "💡 Your fork is synced with upstream."
    echo "   You can add your own knowledge and it will persist across updates."
fi
