import argparse
import json
import hashlib
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Tuple

import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
from tqdm import tqdm


KB_ROOT = Path(__file__).resolve().parents[1]
KNOWLEDGE_DIR = KB_ROOT / "knowledge"
INDEX_DIR = KB_ROOT / ".kb_index"
INDEX_PATH = INDEX_DIR / "index.faiss"
META_PATH = INDEX_DIR / "metadata.json"
CACHE_DIR = INDEX_DIR / "cache"
CACHE_INDEX = INDEX_DIR / "cache_index.json"


@dataclass
class Chunk:
    text: str
    path: str
    heading: str


def strip_frontmatter(text: str) -> str:
    if not text.startswith("---"):
        return text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return text
    return parts[2].lstrip("\n")


def iter_markdown_files(root: Path) -> Iterable[Path]:
    for path in root.rglob("*.md"):
        if path.name.startswith("_"):
            continue
        yield path


def split_into_chunks(path: Path) -> List[Chunk]:
    raw = path.read_text(encoding="utf-8")
    content = strip_frontmatter(raw)
    lines = content.splitlines()

    chunks: List[Chunk] = []
    current_heading = "Document"
    current_lines: List[str] = []

    def flush():
        if not current_lines:
            return
        text = "\n".join(current_lines).strip()
        if text:
            chunks.append(
                Chunk(
                    text=text,
                    path=str(path.relative_to(KB_ROOT)),
                    heading=current_heading,
                )
            )

    for line in lines:
        if line.startswith("#"):
            flush()
            current_heading = line.lstrip("#").strip() or "Document"
            current_lines = [line]
        else:
            current_lines.append(line)

    flush()
    return chunks


def load_corpus() -> List[Chunk]:
    chunks: List[Chunk] = []
    files = list(iter_markdown_files(KNOWLEDGE_DIR))
    for path in tqdm(files, desc="Reading files", unit="file"):
        chunks.extend(split_into_chunks(path))
    return chunks


def file_hash(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha256(data).hexdigest()


def safe_key(path: Path) -> str:
    return str(path.relative_to(KB_ROOT)).replace("/", "__")


def load_cache_index() -> dict:
    if not CACHE_INDEX.exists():
        return {"files": {}}
    return json.loads(CACHE_INDEX.read_text(encoding="utf-8"))


def save_cache_index(index: dict) -> None:
    CACHE_INDEX.write_text(json.dumps(index, indent=2), encoding="utf-8")


def build_index(model: SentenceTransformer) -> None:
    INDEX_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    cache_index = load_cache_index()
    new_index = {"files": {}}

    all_chunks: List[Chunk] = []
    all_embeddings: List[np.ndarray] = []
    reused_files: List[str] = []
    rebuilt_files: List[str] = []

    files = list(iter_markdown_files(KNOWLEDGE_DIR))
    for path in tqdm(files, desc="Indexing files", unit="file"):
        rel_path = str(path.relative_to(KB_ROOT))
        key = safe_key(path)
        current_hash = file_hash(path)

        cache_entry = cache_index["files"].get(rel_path)
        cache_meta_path = CACHE_DIR / f"{key}.json"
        cache_emb_path = CACHE_DIR / f"{key}.npy"

        if cache_entry and cache_entry["hash"] == current_hash:
            meta = json.loads(cache_meta_path.read_text(encoding="utf-8"))
            embeddings = np.load(cache_emb_path)
            chunks = [Chunk(**c) for c in meta["chunks"]]
            reused_files.append(rel_path)
        else:
            chunks = split_into_chunks(path)
            texts = [c.text for c in chunks]
            embeddings = model.encode(
                texts, normalize_embeddings=True, show_progress_bar=False
            )
            embeddings = np.asarray(embeddings, dtype="float32")
            cache_meta_path.write_text(
                json.dumps(
                    {"hash": current_hash, "chunks": [c.__dict__ for c in chunks]},
                    indent=2,
                ),
                encoding="utf-8",
            )
            np.save(cache_emb_path, embeddings)
            rebuilt_files.append(rel_path)

        new_index["files"][rel_path] = {"hash": current_hash, "key": key}
        all_chunks.extend(chunks)
        all_embeddings.append(embeddings)

    for rel_path, entry in cache_index["files"].items():
        if rel_path in new_index["files"]:
            continue
        key = entry["key"]
        (CACHE_DIR / f"{key}.json").unlink(missing_ok=True)
        (CACHE_DIR / f"{key}.npy").unlink(missing_ok=True)

    save_cache_index(new_index)

    print(f"Reused files: {len(reused_files)}")
    if reused_files:
        print("Reused:")
        for path in reused_files:
            print(f"- {path}")
    print(f"Rebuilt files: {len(rebuilt_files)}")
    if rebuilt_files:
        print("Rebuilt:")
        for path in rebuilt_files:
            print(f"- {path}")

    dim = model.get_sentence_embedding_dimension()
    if all_embeddings:
        embeddings = np.vstack(all_embeddings)
    else:
        embeddings = np.zeros((0, dim), dtype="float32")
    print(f"Chunks: {len(all_chunks)}")

    index = faiss.IndexFlatIP(embeddings.shape[1])
    index.add(embeddings)
    faiss.write_index(index, str(INDEX_PATH))

    metadata = [
        {"path": c.path, "heading": c.heading, "text": c.text} for c in all_chunks
    ]
    META_PATH.write_text(json.dumps(metadata, indent=2), encoding="utf-8")


def load_index() -> Tuple[faiss.Index, List[dict]]:
    if not INDEX_PATH.exists() or not META_PATH.exists():
        raise FileNotFoundError("Index not found. Run with --rebuild to create it.")
    index = faiss.read_index(str(INDEX_PATH))
    metadata = json.loads(META_PATH.read_text(encoding="utf-8"))
    return index, metadata


def search(query: str, k: int, min_score: float, model: SentenceTransformer) -> List[dict]:
    index, metadata = load_index()
    q = model.encode([query], normalize_embeddings=True)
    q = np.asarray(q, dtype="float32")
    scores, ids = index.search(q, k)

    results = []
    for score, idx in zip(scores[0], ids[0]):
        if idx < 0:
            continue
        if float(score) < min_score:
            continue
        item = metadata[idx].copy()
        item["score"] = float(score)
        results.append(item)
    return results


def print_results(results: List[dict]) -> None:
    for i, r in enumerate(results, start=1):
        print(f"{i}. {r['path']} -> {r['heading']} (score: {r['score']:.3f})")
        snippet = r["text"].strip().splitlines()
        preview = "\n".join(snippet[:8])
        print(preview)
        print("---")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Search the KB offline.")
    parser.add_argument("query", help="Search query string")
    parser.add_argument("--k", type=int, default=5, help="Number of results")
    parser.add_argument(
        "--rebuild", action="store_true", help="Rebuild the index before search"
    )
    parser.add_argument(
        "--model",
        default="sentence-transformers/all-MiniLM-L6-v2",
        help="Local model name or path",
    )
    parser.add_argument(
        "--min-score",
        type=float,
        default=0.7,
        help="Minimum similarity score to include a result",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    model = SentenceTransformer(args.model)
    if args.rebuild or not INDEX_PATH.exists():
        build_index(model)
    results = search(args.query, args.k, args.min_score, model)
    print_results(results)


if __name__ == "__main__":
    main()
