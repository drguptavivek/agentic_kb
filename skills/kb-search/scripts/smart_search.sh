#!/bin/bash
# Smart KB search: Try Typesense first, fallback to FAISS if no good results
# Usage: ./smart_search.sh "query" [--filter "filter_expr"] [--min-score 0.8]
#
# Arguments:
#   query       - Search query (required)
#   --filter    - Typesense filter expression (optional)
#   --min-score - Minimum similarity score for FAISS (default: 0.7)
#
# Examples:
#   ./smart_search.sh "page numbering pandoc"
#   ./smart_search.sh "search" --filter "domain:Search && type:howto"
#   ./smart_search.sh "git workflow" --min-score 0.8

set -e

# Parse arguments
QUERY=""
FILTER=""
MIN_SCORE="0.7"
KB_PATH="agentic_kb"

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
    echo "Usage: $0 \"query\" [--filter \"filter\"] [--min-score 0.8]"
    exit 1
fi

echo "🔍 Searching KB for: $QUERY"
echo ""

# Try Typesense first
echo "📊 Trying Typesense (fast full-text search)..."
TYPESENSE_CMD="uv run --with typesense python $KB_PATH/scripts/search_typesense.py \"$QUERY\""
if [ -n "$FILTER" ]; then
    TYPESENSE_CMD="$TYPESENSE_CMD --filter \"$FILTER\""
fi

if eval "$TYPESENSE_CMD" > /tmp/typesense_results.txt 2>&1; then
    # Check if we got good results (more than just header lines)
    RESULT_COUNT=$(cat /tmp/typesense_results.txt | wc -l)

    if [ "$RESULT_COUNT" -gt 5 ]; then
        echo "✅ Found results in Typesense:"
        echo ""
        cat /tmp/typesense_results.txt
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

cd "$KB_PATH"
uv run --with faiss-cpu --with numpy --with sentence-transformers python scripts/search.py "$QUERY" --min-score "$MIN_SCORE"
cd ..
