#!/bin/bash
# Initial setup for agentic_kb knowledge base
# Guides users through forking and setting up their own KB
#
# Usage: ./setup_kb.sh [submodule_path] [--read-only] [--default] [--fork-url URL] [--central]
#
# Arguments:
#   submodule_path - Path for the KB submodule (default: agentic_kb)
#   --read-only    - Skip fork setup, add as read-only submodule
#   --default      - Use upstream KB directly as submodule origin
#   --fork-url     - Use provided fork URL as submodule (no prompts)
#   --central      - Clone/update a shared KB at ~/.agentic_kb instead of adding a submodule

set -e

SUBMODULE_PATH="agentic_kb"
READ_ONLY=false
CENTRAL=false
FORK_URL=""
UPSTREAM_REPO="https://github.com/drguptavivek/agentic_kb.git"
CENTRAL_PATH="${AGENTIC_KB_PATH:-$HOME/.agentic_kb}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --read-only)
            READ_ONLY=true
            shift
            ;;
        --central)
            CENTRAL=true
            shift
            ;;
        --fork-url)
            FORK_URL="$2"
            shift 2
            ;;
        --default)
            FORK_URL="$UPSTREAM_REPO"
            shift
            ;;
        *)
            SUBMODULE_PATH="$1"
            shift
            ;;
    esac
done

echo "🚀 Setting up agentic_kb knowledge base"
echo ""

if [ "$CENTRAL" = true ]; then
    CLONE_URL="${FORK_URL:-$UPSTREAM_REPO}"
    echo "🌐 Setting up centralized KB at: $CENTRAL_PATH"
    echo ""

    if [ -e "$CENTRAL_PATH" ] && [ ! -d "$CENTRAL_PATH/.git" ]; then
        echo "❌ Error: $CENTRAL_PATH exists but is not a git repository"
        exit 1
    fi

    if [ -d "$CENTRAL_PATH/.git" ]; then
        echo "✅ Central KB already exists"
        echo "📥 Pulling latest changes..."
        git -C "$CENTRAL_PATH" pull --ff-only origin main || git -C "$CENTRAL_PATH" pull --ff-only origin master
    else
        echo "📥 Cloning KB..."
        git clone "$CLONE_URL" "$CENTRAL_PATH"
    fi

    echo ""
    echo "✅ Central KB is ready at: $CENTRAL_PATH"
    echo ""
    echo "Use from any project:"
    echo "  $CENTRAL_PATH/scripts/smart_search.sh \"your query\""
    echo "  $CENTRAL_PATH/scripts/update_kb.sh"
    echo ""
    echo "Optional environment override:"
    echo "  export AGENTIC_KB_PATH=\"$CENTRAL_PATH\""
    exit 0
fi

# Check if KB already exists
if [ -d "$SUBMODULE_PATH" ]; then
    echo "✅ KB already exists at: $SUBMODULE_PATH"
    echo ""

    # Check if it's a git repository
    if [ -d "$SUBMODULE_PATH/.git" ]; then
        cd "$SUBMODULE_PATH"
        CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")

        echo "Current remote: $CURRENT_REMOTE"
        echo ""

        # Check if upstream is set
        UPSTREAM_REMOTE=$(git remote get-url upstream 2>/dev/null || echo "")

        if [ -z "$UPSTREAM_REMOTE" ] && [ "$CURRENT_REMOTE" != "$UPSTREAM_REPO" ]; then
            echo "📌 Adding upstream remote for syncing with original KB..."
            git remote add upstream "$UPSTREAM_REPO"
            echo "✅ Upstream remote added: $UPSTREAM_REPO"
            echo ""
            echo "To sync with upstream in the future:"
            echo "  cd $SUBMODULE_PATH"
            echo "  git fetch upstream"
            echo "  git merge upstream/main"
            echo "  git push origin main"
        elif [ -n "$UPSTREAM_REMOTE" ]; then
            echo "✅ Upstream remote already configured: $UPSTREAM_REMOTE"
        fi

        cd - > /dev/null
        exit 0
    fi
fi

# New setup flow
echo "This will set up the agentic_kb knowledge base in your project."
echo ""

if [ "$READ_ONLY" = true ]; then
    echo "🔍 Setting up READ-ONLY access (you won't be able to push changes)"
    echo ""
    echo "Adding KB as read-only submodule..."

    git submodule add "$UPSTREAM_REPO" "$SUBMODULE_PATH"
    git add .gitmodules "$SUBMODULE_PATH"

    echo ""
    echo "✅ KB added as read-only submodule"
    echo ""
    echo "⚠️  Note: You won't be able to push changes to this KB."
    echo "   If you want to add your own knowledge later, remove this"
    echo "   submodule and re-run setup without --read-only flag."
    echo ""
    echo "Next step: git commit -m \"Add: agentic_kb submodule (read-only)\""
    exit 0
fi

if [ -z "$FORK_URL" ]; then
    echo "❌ Error: Please provide --fork-url <URL>, --default, or use --read-only"
    echo "Create a fork first:"
    echo "  Web: https://github.com/drguptavivek/agentic_kb"
    echo "  CLI: gh repo fork drguptavivek/agentic_kb --clone=false"
    exit 1
fi

# Add submodule
echo "📥 Adding KB submodule..."
git submodule add "$FORK_URL" "$SUBMODULE_PATH"

if [ "$FORK_URL" != "$UPSTREAM_REPO" ]; then
    # Add upstream remote
    echo "📌 Setting up upstream remote..."
    cd "$SUBMODULE_PATH"
    git remote add upstream "$UPSTREAM_REPO"
    cd - > /dev/null
fi

# Stage changes
echo "💾 Staging changes..."
git add .gitmodules "$SUBMODULE_PATH"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Your KB is configured at: $SUBMODULE_PATH"
if [ "$FORK_URL" != "$UPSTREAM_REPO" ]; then
    echo "   Origin (your fork): $FORK_URL"
    echo "   Upstream (original): $UPSTREAM_REPO"
    echo ""
    echo "Next steps:"
    echo "  1. git commit -m \"Add: agentic_kb submodule (personal fork)\""
    echo "  2. git push"
    echo ""
    echo "To sync with upstream updates later:"
    echo "  cd $SUBMODULE_PATH"
    echo "  git fetch upstream"
    echo "  git merge upstream/main"
    echo "  git push origin main"
    echo "  cd .."
    echo "  git add $SUBMODULE_PATH"
    echo "  git commit -m \"Update: agentic_kb synced with upstream\""
    echo "  git push"
else
    echo "   Origin: $FORK_URL"
    echo ""
    echo "Next step: git commit -m \"Add: agentic_kb submodule (default KB)\""
fi
