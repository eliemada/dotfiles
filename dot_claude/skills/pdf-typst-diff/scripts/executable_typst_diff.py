#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Diff two Typst (.typ) files: unified text diff, side-by-side HTML,
JSON statistics, and an annotated Typst file with insertions/deletions
marked using #strike and #highlight.

The annotated .typ compiles to a redlined PDF via `typst compile`.
"""
from __future__ import annotations

import argparse
import difflib
import html
import json
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path

# Typst helpers prepended to the annotated output so #ins / #del are styled.
TYPST_PREAMBLE = """\
#let ins(body) = highlight(fill: rgb("#c6f6c6"))[#body]
#let del(body) = text(fill: red)[#strike[#body]]

"""

# Tokens for word-level diff: words, whitespace runs, and punctuation kept
# as separate tokens so the diff stays readable when reassembled.
_TOKEN_RE = re.compile(r"\w+|\s+|[^\w\s]", flags=re.UNICODE)


def tokenize(text: str) -> list[str]:
    return _TOKEN_RE.findall(text)


def unwrap_pdf_linebreaks(text: str) -> str:
    """PDFs often inject hard line breaks mid-paragraph. Collapse single
    newlines (between non-empty lines) while preserving paragraph breaks
    (>=2 newlines)."""
    # Protect double newlines.
    placeholder = "\x00PARA\x00"
    text = re.sub(r"\n{2,}", placeholder, text)
    text = re.sub(r"\n+", " ", text)
    text = text.replace(placeholder, "\n\n")
    return text


# ---------- Diff payloads -------------------------------------------------

@dataclass
class DiffStats:
    a_path: str
    b_path: str
    a_chars: int
    b_chars: int
    a_tokens: int
    b_tokens: int
    inserted_tokens: int
    deleted_tokens: int
    equal_tokens: int
    similarity: float  # difflib ratio in [0, 1]


def compute_stats(a: str, b: str, a_path: Path, b_path: Path) -> tuple[DiffStats, list[tuple[str, str]]]:
    """Returns (stats, opcodes-with-text). Opcodes are (tag, joined_text)
    where tag ∈ {'equal','insert','delete','replace'}."""
    a_tok = tokenize(a)
    b_tok = tokenize(b)
    sm = difflib.SequenceMatcher(a=a_tok, b=b_tok, autojunk=False)

    inserted = deleted = equal = 0
    chunks: list[tuple[str, str]] = []
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        a_part = "".join(a_tok[i1:i2])
        b_part = "".join(b_tok[j1:j2])
        if tag == "equal":
            equal += (i2 - i1)
            chunks.append(("equal", a_part))
        elif tag == "insert":
            inserted += (j2 - j1)
            chunks.append(("insert", b_part))
        elif tag == "delete":
            deleted += (i2 - i1)
            chunks.append(("delete", a_part))
        elif tag == "replace":
            deleted += (i2 - i1)
            inserted += (j2 - j1)
            chunks.append(("delete", a_part))
            chunks.append(("insert", b_part))

    stats = DiffStats(
        a_path=str(a_path),
        b_path=str(b_path),
        a_chars=len(a),
        b_chars=len(b),
        a_tokens=len(a_tok),
        b_tokens=len(b_tok),
        inserted_tokens=inserted,
        deleted_tokens=deleted,
        equal_tokens=equal,
        similarity=round(sm.ratio(), 5),
    )
    return stats, chunks


# ---------- Renderers -----------------------------------------------------

# Typst special characters that need escaping when wrapped in ins/del.
# We escape just enough to avoid breaking the macro arguments.
_TYPST_ESCAPE = str.maketrans({
    "\\": "\\\\",
    "#": "\\#",
    "[": "\\[",
    "]": "\\]",
    "$": "\\$",
    "@": "\\@",
})


def render_annotated_typst(chunks: list[tuple[str, str]]) -> str:
    """Reconstruct the file with #ins[...]/#del[...] around changed runs.
    Equal runs pass through untouched (preserving original Typst syntax)."""
    out: list[str] = [TYPST_PREAMBLE]
    for tag, text in chunks:
        if not text:
            continue
        if tag == "equal":
            out.append(text)
        elif tag == "insert":
            out.append("#ins[" + text.translate(_TYPST_ESCAPE) + "]")
        elif tag == "delete":
            out.append("#del[" + text.translate(_TYPST_ESCAPE) + "]")
    return "".join(out)


def render_unified(a: str, b: str, a_path: Path, b_path: Path, context: int = 3) -> str:
    return "".join(difflib.unified_diff(
        a.splitlines(keepends=True),
        b.splitlines(keepends=True),
        fromfile=str(a_path),
        tofile=str(b_path),
        n=context,
    ))


def render_side_by_side_html(a: str, b: str, a_path: Path, b_path: Path) -> str:
    """Uses difflib.HtmlDiff for the side-by-side view, with a slim CSS reset."""
    table = difflib.HtmlDiff(wrapcolumn=80).make_table(
        a.splitlines(),
        b.splitlines(),
        fromdesc=html.escape(str(a_path)),
        todesc=html.escape(str(b_path)),
        context=False,
    )
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Typst diff</title>
<style>
 body {{ font-family: -apple-system, system-ui, sans-serif; margin: 24px; }}
 table.diff {{ font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px;
              border-collapse: collapse; width: 100%; }}
 .diff_header {{ background: #f0f0f0; color: #555; }}
 td.diff_header {{ text-align: right; padding: 0 6px; }}
 .diff_next {{ background: #f8f8f8; }}
 .diff_add {{ background: #c6f6c6; }}
 .diff_chg {{ background: #fff5b1; }}
 .diff_sub {{ background: #ffd7d7; }}
</style></head>
<body>
<h1>Typst diff</h1>
<p><b>A:</b> {html.escape(str(a_path))}<br><b>B:</b> {html.escape(str(b_path))}</p>
{table}
</body></html>
"""


# ---------- Driver --------------------------------------------------------

def diff_files(a_path: Path, b_path: Path, out_dir: Path, unwrap: bool = True) -> DiffStats:
    out_dir.mkdir(parents=True, exist_ok=True)
    a_raw = a_path.read_text()
    b_raw = b_path.read_text()
    a = unwrap_pdf_linebreaks(a_raw) if unwrap else a_raw
    b = unwrap_pdf_linebreaks(b_raw) if unwrap else b_raw

    stats, chunks = compute_stats(a, b, a_path, b_path)

    (out_dir / "unified.diff").write_text(render_unified(a, b, a_path, b_path))
    (out_dir / "side_by_side.html").write_text(render_side_by_side_html(a, b, a_path, b_path))
    (out_dir / "annotated.typ").write_text(render_annotated_typst(chunks))
    (out_dir / "report.json").write_text(json.dumps(asdict(stats), indent=2))

    return stats


def main() -> int:
    ap = argparse.ArgumentParser(description="Diff two Typst (.typ) files.")
    ap.add_argument("a", type=Path, help="Old / reference .typ")
    ap.add_argument("b", type=Path, help="New / candidate .typ")
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument(
        "--no-unwrap",
        action="store_true",
        help="Do not collapse mid-paragraph hard line breaks before diffing",
    )
    args = ap.parse_args()

    stats = diff_files(args.a, args.b, args.out, unwrap=not args.no_unwrap)
    print(json.dumps(asdict(stats), indent=2))
    print(f"\n[done] artifacts in {args.out}/  (unified.diff, side_by_side.html, annotated.typ, report.json)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
