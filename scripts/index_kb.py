from pathlib import Path
import sys

from sentence_transformers import SentenceTransformer

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts.search import build_index, INDEX_PATH  # noqa: E402


def main() -> None:
    model = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
    build_index(model)
    print(f"Index built at {INDEX_PATH}")


if __name__ == "__main__":
    main()
