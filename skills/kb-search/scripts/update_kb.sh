#!/bin/bash
# Update agentic_kb submodule to latest version
# Handles both direct repo and forked repo scenarios
#
# Usage: ./update_kb.sh [submodule_path] [--sync-upstream]
#
# Arguments:
#   submodule_path   - Path to the KB submodule (default: agentic_kb)
#   --sync-upstream  - Force sync with upstream (for forks)

set -e

SUBMODULE_PATH="${1:-agentic_kb}"
SYNC_UPSTREAM=false

# Parse flags
for arg in "$@"; do
    if [ "$arg" = "--sync-upstream" ]; then
        SYNC_UPSTREAM=true
    fi
done

echo "🔄 Updating KB submodule: $SUBMODULE_PATH"
echo ""

# Check if submodule exists
if [ ! -d "$SUBMODULE_PATH" ]; then
    echo "❌ Error: Submodule not found at $SUBMODULE_PATH"
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

# Update parent project's submodule pointer
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

echo ""
echo "📚 KB is now up to date!"

# Show helpful info for forks
if [ "$HAS_UPSTREAM" -gt 0 ]; then
    echo ""
    echo "💡 Your fork is synced with upstream."
    echo "   You can add your own knowledge and it will persist across updates."
fi
