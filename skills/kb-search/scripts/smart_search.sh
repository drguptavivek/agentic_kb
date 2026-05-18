#!/bin/bash
# Smart KB search: Try Typesense first, fallback to FAISS if no good results
# Usage: ./smart_search.sh "query" [--filter "filter_expr"] [--min-score 0.8] [--kb-path PATH]
#
# Arguments:
#   query       - Search query (required)
#   --filter    - Typesense filter expression (optional)
#   --min-score - Minimum similarity score for FAISS (default: 0.7)
#   --kb-path   - Path to KB root (optional; auto-detected)
#
# Examples:
#   ./smart_search.sh "page numbering pandoc"
#   ./smart_search.sh "search" --filter "domain:Search && type:howto"
#   ./smart_search.sh "git workflow" --min-score 0.8

set -euo pipefail

# Parse arguments
QUERY=""
FILTER=""
MIN_SCORE="0.7"
KB_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --min-score)
            MIN_SCORE="$2"
            shift 2
            ;;
        --kb-path)
            KB_PATH="$2"
            shift 2
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

if [ -z "$QUERY" ]; then
    echo "❌ Error: Query is required"
    echo "Usage: $0 \"query\" [--filter \"filter\"] [--min-score 0.8] [--kb-path PATH]"
    exit 1
fi

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

if [ -z "$KB_PATH" ]; then
    if ! KB_PATH="$(detect_kb_path)"; then
        echo "❌ Error: Could not auto-detect KB path."
        echo "   Pass --kb-path to the KB root (contains knowledge/ and scripts/)."
        exit 1
    fi
fi

echo "🔍 Searching KB for: $QUERY"
echo ""

# Keep uv generated state in predictable KB-local paths.
if [ "$KB_PATH" = "." ]; then
    KB_ABS_PATH="$(pwd)"
else
    KB_ABS_PATH="$(cd "$KB_PATH" && pwd)"
fi
export UV_CACHE_DIR="${AGENTIC_KB_UV_CACHE_DIR:-$KB_ABS_PATH/.uv-cache}"
export UV_PROJECT_ENVIRONMENT="${AGENTIC_KB_UV_ENV:-$KB_ABS_PATH/.venv}"
mkdir -p "$UV_CACHE_DIR" "$UV_PROJECT_ENVIRONMENT" || {
    echo "❌ Error: Cannot write KB uv state."
    echo "   Allow write access to: $UV_CACHE_DIR"
    echo "   Allow write access to: $UV_PROJECT_ENVIRONMENT"
    echo "   Or set AGENTIC_KB_UV_CACHE_DIR and AGENTIC_KB_UV_ENV to writable paths."
    exit 1
}
KB_PYTHON="$UV_PROJECT_ENVIRONMENT/bin/python"

# Try Typesense first
echo "📊 Trying Typesense (fast full-text search)..."
if [ -x "$KB_PYTHON" ]; then
    TYPESENSE_CMD="\"$KB_PYTHON\" \"$KB_ABS_PATH/scripts/search_typesense.py\" \"$QUERY\""
else
    TYPESENSE_CMD="uv run --no-project --with typesense python \"$KB_ABS_PATH/scripts/search_typesense.py\" \"$QUERY\""
fi
if [ -n "$FILTER" ]; then
    TYPESENSE_CMD="$TYPESENSE_CMD --filter \"$FILTER\""
fi

TMP_RESULTS="$(mktemp -t typesense_results.XXXXXX)"
trap 'rm -f "$TMP_RESULTS"' EXIT

if eval "$TYPESENSE_CMD" > "$TMP_RESULTS" 2>&1; then
    # Check if we got good results (more than just header lines)
    RESULT_COUNT=$(cat "$TMP_RESULTS" | wc -l)

    if [ "$RESULT_COUNT" -gt 5 ]; then
        echo "✅ Found results in Typesense:"
        echo ""
        cat "$TMP_RESULTS"
        exit 0
    else
        echo "⚠️  Typesense returned few/no results"
    fi
else
    echo "⚠️  Typesense search failed (server might not be running)"
fi

# Fallback to FAISS
echo ""
echo "🧠 Falling back to FAISS (semantic vector search)..."
echo ""

(
    cd "$KB_ABS_PATH"
    if [ -x "$KB_PYTHON" ]; then
        "$KB_PYTHON" scripts/search.py "$QUERY" --min-score "$MIN_SCORE"
    else
        uv run --no-project --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "$QUERY" --min-score "$MIN_SCORE"
    fi
)
