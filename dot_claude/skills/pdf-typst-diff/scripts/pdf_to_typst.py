#!/usr/bin/env python3
"""Convert a PDF to a Typst (.typ) source file.

Pipeline:
    PDF --[backend]--> Markdown --[pandoc -t typst]--> Typst (.typ)

Backends (in order of fidelity vs setup cost):
    pymupdf4llm : pure-python, fast, no ML model. Default.
    marker      : SOTA layout/equations/tables, requires `marker-pdf` install + model.
    docling     : IBM, strong on tables/formulas, requires `docling` install + model.

State-of-the-art note: Pandoc gained a native Typst writer in v3.0 (2023).
Earlier versions cannot emit .typ — `pypandoc-binary` ships a recent build.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


# ---------- Backends ------------------------------------------------------

def md_from_pymupdf4llm(pdf: Path) -> str:
    """Default backend: PyMuPDF's markdown extractor. Born-digital text PDFs."""
    import pymupdf4llm  # type: ignore
    return pymupdf4llm.to_markdown(str(pdf))


def md_from_marker(pdf: Path) -> str:
    """SOTA layout-aware backend. Heavy install (~5 GB model)."""
    from marker.converters.pdf import PdfConverter  # type: ignore
    from marker.models import create_model_dict  # type: ignore
    from marker.output import text_from_rendered  # type: ignore

    converter = PdfConverter(artifact_dict=create_model_dict())
    rendered = converter(str(pdf))
    text, _, _ = text_from_rendered(rendered)
    return text


def md_from_docling(pdf: Path) -> str:
    """IBM's docling. Excellent table/formula extraction."""
    from docling.document_converter import DocumentConverter  # type: ignore

    converter = DocumentConverter()
    result = converter.convert(str(pdf))
    return result.document.export_to_markdown()


BACKENDS = {
    "pymupdf4llm": md_from_pymupdf4llm,
    "marker": md_from_marker,
    "docling": md_from_docling,
}


# ---------- Markdown → Typst (Pandoc) ------------------------------------

def md_to_typst(md: str) -> str:
    """Pipe markdown through Pandoc's native Typst writer."""
    import pypandoc  # type: ignore
    return pypandoc.convert_text(md, to="typst", format="markdown")


# ---------- Post-processing ----------------------------------------------

_PANDOC_PREAMBLE = re.compile(r"^// Generated.*?\n", re.MULTILINE)


def clean_typst(src: str) -> str:
    """Remove Pandoc preamble noise and normalize whitespace."""
    src = _PANDOC_PREAMBLE.sub("", src)
    # Collapse 3+ blank lines to a single paragraph break.
    src = re.sub(r"\n{3,}", "\n\n", src)
    return src.strip() + "\n"


# ---------- Driver --------------------------------------------------------

def convert(pdf: Path, out: Path, backend: str, keep_md: bool = False) -> Path:
    if not pdf.exists():
        raise FileNotFoundError(pdf)
    if backend not in BACKENDS:
        raise ValueError(f"backend must be one of {list(BACKENDS)}")

    md = BACKENDS[backend](pdf)
    if keep_md:
        md_path = out.with_suffix(".md")
        md_path.write_text(md)
        print(f"[md] {md_path}", file=sys.stderr)

    typst = clean_typst(md_to_typst(md))
    out.write_text(typst)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Convert a PDF to Typst (.typ).")
    ap.add_argument("pdf", type=Path)
    ap.add_argument("--out", type=Path, required=True, help="Output .typ path")
    ap.add_argument(
        "--backend",
        choices=list(BACKENDS),
        default="pymupdf4llm",
        help="Extraction backend (pymupdf4llm default; marker/docling for higher fidelity)",
    )
    ap.add_argument("--keep-md", action="store_true", help="Also write intermediate .md")
    args = ap.parse_args()

    path = convert(args.pdf, args.out, args.backend, args.keep_md)
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
