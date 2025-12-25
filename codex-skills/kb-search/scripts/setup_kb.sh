#!/bin/bash
# Initial setup for agentic_kb knowledge base
# Guides users through forking and setting up their own KB
#
# Usage: ./setup_kb.sh [submodule_path] [--read-only]
#
# Arguments:
#   submodule_path - Path for the KB submodule (default: agentic_kb)
#   --read-only    - Skip fork setup, add as read-only submodule

set -e

SUBMODULE_PATH="agentic_kb"
READ_ONLY=false
UPSTREAM_REPO="https://github.com/drguptavivek/agentic_kb.git"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --read-only)
            READ_ONLY=true
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

# Interactive fork setup
echo "📋 Setup Options:"
echo ""
echo "1. Fork & Customize (Recommended)"
echo "   - Create your own fork on GitHub"
echo "   - Add and modify knowledge as needed"
echo "   - Sync with upstream for updates"
echo ""
echo "2. Read-Only Access"
echo "   - Use KB as-is without modifications"
echo "   - Cannot push changes"
echo "   - Re-run with --read-only flag"
echo ""

read -p "Do you want to create a fork? [Y/n] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    echo ""
    echo "Please re-run with --read-only flag for read-only access:"
    echo "  ./setup_kb.sh --read-only"
    exit 0
fi

echo ""
echo "📝 Fork Setup Instructions:"
echo ""
echo "1. Go to: https://github.com/drguptavivek/agentic_kb"
echo "2. Click the 'Fork' button (top-right)"
echo "3. Create the fork in your GitHub account"
echo "4. Copy your fork's URL (should be: https://github.com/YOUR_USERNAME/agentic_kb.git)"
echo ""

read -p "Have you forked the repository? [Y/n] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
    echo ""
    echo "Please fork the repository first, then re-run this script."
    echo "Fork at: https://github.com/drguptavivek/agentic_kb"
    exit 0
fi

echo ""
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ Error: GitHub username is required"
    exit 1
fi

FORK_URL="https://github.com/$GITHUB_USERNAME/agentic_kb.git"

echo ""
echo "Using fork URL: $FORK_URL"
echo ""

# Add submodule
echo "📥 Adding KB submodule from your fork..."
git submodule add "$FORK_URL" "$SUBMODULE_PATH"

# Add upstream remote
echo "📌 Setting up upstream remote..."
cd "$SUBMODULE_PATH"
git remote add upstream "$UPSTREAM_REPO"
cd - > /dev/null

# Stage changes
echo "💾 Staging changes..."
git add .gitmodules "$SUBMODULE_PATH"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Your KB is configured at: $SUBMODULE_PATH"
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
