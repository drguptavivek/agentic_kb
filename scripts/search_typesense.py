import argparse
import os
import sys
from contextlib import contextmanager
from io import StringIO
from typing import List

import typesense


@contextmanager
def suppress_typesense_warnings():
    """Suppress Typesense v30+ deprecation warnings printed to stderr."""
    old_stderr = sys.stderr
    sys.stderr = StringIO()
    try:
        yield
    finally:
        sys.stderr = old_stderr


def create_client(host: str, port: int, api_key: str) -> typesense.Client:
    """Create Typesense client."""
    return typesense.Client({
        'nodes': [{
            'host': host,
            'port': port,
            'protocol': 'http'
        }],
        'api_key': api_key,
        'connection_timeout_seconds': 2
    })


def search(
    client: typesense.Client,
    collection_name: str,
    query: str,
    k: int = 5,
    filter_by: str = "",
    query_by: str = "text,heading,path",
) -> List[dict]:
    """Search the KB using Typesense."""
    search_params = {
        'q': query,
        'query_by': query_by,
        'per_page': k,
        'prefix': False,  # Exact matching (set to True for prefix matching)
    }

    if filter_by:
        search_params['filter_by'] = filter_by

    try:
        results = client.collections[collection_name].documents.search(search_params)
        return results.get('hits', [])
    except Exception as e:
        print(f"Search error: {e}")
        return []


def print_results(results: List[dict]) -> None:
    """Pretty-print search results."""
    if not results:
        print("No results found.")
        return

    for i, hit in enumerate(results, start=1):
        doc = hit['document']
        score = hit.get('text_match', 0)

        print(f"{i}. {doc['path']} -> {doc['heading']} (score: {score})")

        # Show tags if available
        if doc.get('tags'):
            print(f"   Tags: {', '.join(doc['tags'])}")

        # Show text snippet
        text = doc['text'].strip().splitlines()
        preview = "\n".join(text[:8])
        print(preview)
        print("---")


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Search the KB using Typesense full-text search."
    )
    parser.add_argument("query", help="Search query string")
    parser.add_argument(
        "--host",
        default=os.getenv("TYPESENSE_HOST", "localhost"),
        help="Typesense host (default: localhost or TYPESENSE_HOST env var)"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.getenv("TYPESENSE_PORT", "8108")),
        help="Typesense port (default: 8108 or TYPESENSE_PORT env var)"
    )
    parser.add_argument(
        "--api-key",
        default=os.getenv("TYPESENSE_API_KEY", "xyz"),
        help="Typesense API key (default: xyz or TYPESENSE_API_KEY env var)"
    )
    parser.add_argument(
        "--collection",
        default="kb_chunks",
        help="Collection name (default: kb_chunks)"
    )
    parser.add_argument(
        "--k",
        type=int,
        default=5,
        help="Number of results (default: 5)"
    )
    parser.add_argument(
        "--filter",
        default="",
        help="Filter expression (e.g., 'tags:=[pandoc, markdown]')"
    )
    parser.add_argument(
        "--query-by",
        default="text,heading,path",
        help="Fields to search (default: text,heading,path)"
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    with suppress_typesense_warnings():
        client = create_client(args.host, args.port, args.api_key)
        results = search(
            client,
            args.collection,
            args.query,
            args.k,
            args.filter,
            args.query_by
        )
    print_results(results)


if __name__ == "__main__":
    main()
