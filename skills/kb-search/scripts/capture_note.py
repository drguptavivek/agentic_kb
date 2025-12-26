#!/usr/bin/env python3
import argparse
import datetime as _dt
import os
import re
from pathlib import Path


def _iso_today() -> str:
    return _dt.date.today().isoformat()


def _slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    text = re.sub(r"-{2,}", "-", text).strip("-")
    return text or "untitled"


def _detect_kb_root(start_dir: Path) -> tuple[Path, Path]:
    knowledge_dir = start_dir / "knowledge"
    submodule_knowledge_dir = start_dir / "agentic_kb" / "knowledge"

    if knowledge_dir.is_dir():
        return start_dir, knowledge_dir
    if submodule_knowledge_dir.is_dir():
        return start_dir / "agentic_kb", submodule_knowledge_dir

    raise SystemExit(
        "Could not detect KB root (expected ./knowledge/ or ./agentic_kb/knowledge/). "
        "Run from a project root or pass --kb-root."
    )


def _render_note(
    *,
    title: str,
    note_type: str,
    domain: str,
    tags: list[str],
    status: str,
    created: str,
    updated: str,
) -> str:
    tags_block = "\n".join([f"  - {t}" for t in tags]) if tags else "  - TODO"
    return (
        "---\n"
        f"title: {title}\n"
        f"type: {note_type}\n"
        f"domain: {domain}\n"
        "tags:\n"
        f"{tags_block}\n"
        f"status: {status}\n"
        f"created: {created}\n"
        f"updated: {updated}\n"
        "---\n\n"
        f"# {title}\n\n"
        "## Overview\n\n"
        "## Problem / Context\n\n"
        "## Steps\n\n"
        "## References\n\n"
        "## Related\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create a new KB note skeleton following KNOWLEDGE_CONVENTIONS.md."
    )
    parser.add_argument("--title", required=True, help="Note title (also used for H1)")
    parser.add_argument(
        "--domain",
        required=True,
        help='Domain folder name, e.g. "Document Automation" or "Search"',
    )
    parser.add_argument(
        "--type",
        default="note",
        choices=["howto", "reference", "checklist", "policy", "note"],
        help="Note type (default: note)",
    )
    parser.add_argument(
        "--status",
        default="draft",
        choices=["draft", "approved", "deprecated"],
        help="Note status (default: draft)",
    )
    parser.add_argument(
        "--tags",
        default="",
        help="Comma-separated tags (recommended: 3-7). Example: pandoc,docx,page-numbering",
    )
    parser.add_argument(
        "--slug",
        default="",
        help="Filename slug without .md (kebab-case). Defaults to slugified title.",
    )
    parser.add_argument(
        "--kb-root",
        default="",
        help="KB root path (directory containing knowledge/). Defaults to auto-detect.",
    )
    parser.add_argument(
        "--created",
        default="",
        help="Created date (YYYY-MM-DD). Defaults to today.",
    )
    parser.add_argument(
        "--updated",
        default="",
        help="Updated date (YYYY-MM-DD). Defaults to created.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing file if it exists.",
    )

    args = parser.parse_args()

    cwd = Path.cwd()
    kb_root = Path(args.kb_root).expanduser().resolve() if args.kb_root else None
    if kb_root:
        knowledge_dir = kb_root / "knowledge"
        if not knowledge_dir.is_dir():
            raise SystemExit(f"--kb-root must contain knowledge/: {kb_root}")
    else:
        kb_root, knowledge_dir = _detect_kb_root(cwd)

    created = args.created or _iso_today()
    updated = args.updated or created

    tags = [t.strip() for t in args.tags.split(",") if t.strip()]
    slug = args.slug.strip() or _slugify(args.title)

    domain_dir = knowledge_dir / args.domain
    out_path = domain_dir / f"{slug}.md"
    domain_dir.mkdir(parents=True, exist_ok=True)

    if out_path.exists() and not args.force:
        raise SystemExit(f"File already exists (use --force to overwrite): {out_path}")

    content = _render_note(
        title=args.title,
        note_type=args.type,
        domain=args.domain,
        tags=tags,
        status=args.status,
        created=created,
        updated=updated,
    )
    out_path.write_text(content, encoding="utf-8")

    rel = os.path.relpath(out_path, Path.cwd())
    print(rel)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
