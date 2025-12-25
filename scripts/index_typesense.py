import argparse
import json
import os
import sys
from contextlib import contextmanager
from io import StringIO
from pathlib import Path
from typing import List, Optional

import typesense
from tqdm import tqdm


@contextmanager
def suppress_typesense_warnings():
    """Suppress Typesense v30+ deprecation warnings printed to stderr."""
    old_stderr = sys.stderr
    sys.stderr = StringIO()
    try:
        yield
    finally:
        sys.stderr = old_stderr

KB_ROOT = Path(__file__).resolve().parents[1]
KNOWLEDGE_DIR = KB_ROOT / "knowledge"


def strip_frontmatter(text: str) -> tuple[str, dict]:
    """Strip YAML frontmatter and return content + metadata."""
    if not text.startswith("---"):
        return text, {}

    parts = text.split("---", 2)
    if len(parts) < 3:
        return text, {}

    frontmatter_raw = parts[1].strip()
    content = parts[2].lstrip("\n")

    # Basic YAML parsing for tags and created date
    metadata = {}
    lines = frontmatter_raw.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("tags:"):
            tags_part = line.replace("tags:", "").strip()
            if tags_part.startswith("[") and tags_part.endswith("]"):
                # JSON-style array: tags: [pandoc, docx]
                metadata["tags"] = json.loads(tags_part)
                i += 1
            elif tags_part:
                # Inline comma-separated: tags: pandoc, docx
                metadata["tags"] = [t.strip() for t in tags_part.split(",")]
                i += 1
            else:
                # YAML list format with hyphens on next lines
                tags = []
                i += 1
                while i < len(lines) and lines[i].strip().startswith("-"):
                    tag = lines[i].strip()[1:].strip()  # Remove hyphen and whitespace
                    if tag:
                        tags.append(tag)
                    i += 1
                metadata["tags"] = tags
        elif line.startswith("created:"):
            metadata["created"] = line.replace("created:", "").strip()
            i += 1
        else:
            i += 1

    return content, metadata


def iter_markdown_files(root: Path):
    """Iterate over all markdown files in the knowledge directory."""
    for path in root.rglob("*.md"):
        if path.name.startswith("_"):
            continue
        yield path


def split_into_chunks(path: Path) -> List[dict]:
    """Split markdown file into searchable chunks."""
    raw = path.read_text(encoding="utf-8")
    content, metadata = strip_frontmatter(raw)
    lines = content.splitlines()

    chunks: List[dict] = []
    current_heading = "Document"
    current_lines: List[str] = []

    def flush():
        if not current_lines:
            return
        text = "\n".join(current_lines).strip()
        if text:
            chunks.append({
                "text": text,
                "path": str(path.relative_to(KB_ROOT)),
                "heading": current_heading,
                "tags": metadata.get("tags", []),
                "created": metadata.get("created", ""),
            })

    for line in lines:
        if line.startswith("#"):
            flush()
            current_heading = line.lstrip("#").strip() or "Document"
            current_lines = [line]
        else:
            current_lines.append(line)

    flush()
    return chunks


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


def create_schema(client: typesense.Client, collection_name: str) -> None:
    """Create or recreate the Typesense collection schema."""
    schema = {
        'name': collection_name,
        'fields': [
            {'name': 'path', 'type': 'string', 'facet': True},
            {'name': 'heading', 'type': 'string', 'facet': False},
            {'name': 'text', 'type': 'string', 'facet': False},
            {'name': 'tags', 'type': 'string[]', 'facet': True, 'optional': True},
            {'name': 'created', 'type': 'string', 'facet': False, 'optional': True},
        ],
        'default_sorting_field': ''
    }

    # Delete existing collection if it exists
    try:
        client.collections[collection_name].delete()
        print(f"Deleted existing collection: {collection_name}")
    except Exception:
        pass

    # Create new collection
    client.collections.create(schema)
    print(f"Created collection: {collection_name}")


def index_documents(client: typesense.Client, collection_name: str, batch_size: int = 100) -> None:
    """Index all KB documents into Typesense."""
    files = list(iter_markdown_files(KNOWLEDGE_DIR))
    all_docs = []

    for path in tqdm(files, desc="Processing files", unit="file"):
        chunks = split_into_chunks(path)
        all_docs.extend(chunks)

    # Import documents in batches
    collection = client.collections[collection_name]
    for i in tqdm(range(0, len(all_docs), batch_size), desc="Indexing batches", unit="batch"):
        batch = all_docs[i:i + batch_size]
        try:
            collection.documents.import_(batch, {'action': 'create'})
        except Exception as e:
            print(f"Error indexing batch {i // batch_size}: {e}")

    print(f"Indexed {len(all_docs)} chunks from {len(files)} files")


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Index KB into Typesense for full-text search."
    )
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
        "--batch-size",
        type=int,
        default=100,
        help="Batch size for indexing (default: 100)"
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point."""
    args = parse_args()

    with suppress_typesense_warnings():
        client = create_client(args.host, args.port, args.api_key)
        create_schema(client, args.collection)
        index_documents(client, args.collection, args.batch_size)

    print(f"\n✓ Index complete. Query at http://{args.host}:{args.port}")


if __name__ == "__main__":
    main()
