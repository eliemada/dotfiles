#!/usr/bin/env python3
"""Apply targeted text edits to a PDF while preserving exact visual fidelity.

For each (old_text, new_text) pair in --edits:
  1. Find every text span in the PDF whose extracted string contains old_text.
  2. Cover the original raster text with a rectangle filled with the
     sampled background color (so it works on white pages AND on coloured
     headers / dark-grey bars).
  3. Overlay the new text at the same position with the same size, weight,
     and color as the original.
Unedited spans get a transparent overlay so the document remains fully
selectable but visually identical to the source.

Edits file is a JSON object: {"old text": "new text", ...}
Substring matches are applied left-to-right within each span, so a single
span like "période du 09.03.2026 au 08.04.2026" can have both dates replaced.

Usage:
  python pdf_edit.py invoice.pdf --edits edits.json --out edited.typ
  typst compile edited.typ edited.pdf
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import fitz  # PyMuPDF


def sample_bg_color(
    pix: fitz.Pixmap, x0_pt: float, y0_pt: float, x1_pt: float, y1_pt: float, scale: float
) -> tuple[int, int, int]:
    """Median color in a 2-px frame just outside the text bbox."""
    px0, py0 = int(x0_pt * scale), int(y0_pt * scale)
    px1, py1 = int(x1_pt * scale), int(y1_pt * scale)
    w, h, n = pix.width, pix.height, pix.n
    samples_at = []
    for x in range(max(0, px0 - 4), min(w, px1 + 4), 2):
        samples_at.append((x, max(0, py0 - 2)))
        samples_at.append((x, min(h - 1, py1 + 2)))
    for y in range(max(0, py0 - 2), min(h, py1 + 2), 2):
        samples_at.append((max(0, px0 - 4), y))
        samples_at.append((min(w - 1, px1 + 4), y))
    samples: list[tuple[int, int, int]] = []
    for x, y in samples_at:
        idx = (y * w + x) * n
        r = pix.samples[idx]
        g = pix.samples[idx + 1] if n >= 3 else r
        b = pix.samples[idx + 2] if n >= 3 else r
        samples.append((r, g, b))
    if not samples:
        return (255, 255, 255)
    samples.sort(key=lambda c: c[0] + c[1] + c[2])
    return samples[len(samples) // 2]


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def weight_kw(font_name: str) -> str:
    n = font_name.lower()
    if "bold" in n or "black" in n or "heavy" in n:
        return ", weight: 700"
    return ""


def apply_edits(text: str, edits: dict[str, str]) -> str | None:
    """Apply all matching edits to a span. Return None if nothing changed."""
    new_text = text
    for old, new in edits.items():
        if old in new_text:
            new_text = new_text.replace(old, new)
    return new_text if new_text != text else None


def edit_pdf(pdf_path: Path, edits: dict[str, str], out_typst: Path, dpi: int = 200) -> tuple[Path, set[str]]:
    if not pdf_path.exists():
        raise FileNotFoundError(pdf_path)
    out_typst.parent.mkdir(parents=True, exist_ok=True)
    assets_dir = out_typst.parent / f"{out_typst.stem}_assets"
    assets_dir.mkdir(exist_ok=True)
    scale = dpi / 72.0

    doc = fitz.open(pdf_path)
    matched: set[str] = set()
    lines: list[str] = []

    for page_idx, page in enumerate(doc):
        w_pt, h_pt = page.rect.width, page.rect.height
        pix = page.get_pixmap(matrix=fitz.Matrix(scale, scale), alpha=False)
        bg_name = f"page_{page_idx + 1:03d}_bg.png"
        pix.save(assets_dir / bg_name)
        bg_rel = f"{assets_dir.name}/{bg_name}"

        if page_idx == 0:
            lines.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")
            lines.append('#set text(font: "Helvetica")')
            lines.append("")
        else:
            lines.append("")
            lines.append("#pagebreak()")
            lines.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")

        lines.append(
            f'#place(top + left, dx: 0pt, dy: 0pt, image("{bg_rel}", '
            f"width: {w_pt:.2f}pt, height: {h_pt:.2f}pt))"
        )

        for block in page.get_text("dict")["blocks"]:
            if block.get("type", 0) != 0:
                continue
            for line in block.get("lines", []):
                for span in line.get("spans", []):
                    text = span["text"]
                    if not text:
                        continue
                    x0, y0, x1, y1 = span["bbox"]
                    size = span["size"]
                    c = span["color"]
                    r, g, b = (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF
                    wkw = weight_kw(span["font"])

                    new_text = apply_edits(text, edits)
                    if new_text is not None:
                        for old in edits:
                            if old in text:
                                matched.add(old)
                        pad_x, pad_y = 2.0, 1.0
                        rect_w = max(1.0, x1 - x0) + pad_x * 2
                        rect_h = max(1.0, y1 - y0) + pad_y * 2
                        bg_r, bg_g, bg_b = sample_bg_color(pix, x0, y0, x1, y1, scale)
                        lines.append(
                            f"#place(top + left, dx: {x0 - pad_x:.2f}pt, dy: {y0 - pad_y:.2f}pt, "
                            f"rect(fill: rgb({bg_r}, {bg_g}, {bg_b}), stroke: none, "
                            f"width: {rect_w:.2f}pt, height: {rect_h:.2f}pt))"
                        )
                        lines.append(
                            f"#place(top + left, dx: {x0:.2f}pt, dy: {y0:.2f}pt, "
                            f'text(size: {size:.2f}pt, fill: rgb({r}, {g}, {b}){wkw}, "{esc(new_text)}"))'
                        )
                    else:
                        lines.append(
                            f"#place(top + left, dx: {x0:.2f}pt, dy: {y0:.2f}pt, "
                            f'text(size: {size:.2f}pt, fill: rgb(0, 0, 0, 0){wkw}, "{esc(text)}"))'
                        )

    out_typst.write_text("\n".join(lines) + "\n")
    return out_typst, matched


def main() -> int:
    ap = argparse.ArgumentParser(description="Apply targeted edits to a PDF, preserving visual fidelity.")
    ap.add_argument("pdf", type=Path)
    ap.add_argument("--edits", type=Path, required=True, help="JSON file: {old: new, ...}")
    ap.add_argument("--out", type=Path, required=True, help="Output .typ path")
    ap.add_argument("--dpi", type=int, default=200, help="Background raster DPI")
    args = ap.parse_args()

    edits = json.loads(args.edits.read_text())
    if not isinstance(edits, dict):
        print("edits file must be a JSON object", file=sys.stderr)
        return 2

    out, matched = edit_pdf(args.pdf, edits, args.out, args.dpi)
    unmatched = sorted(set(edits) - matched)
    print(f"matched   ({len(matched)}): {sorted(matched)}")
    print(f"unmatched ({len(unmatched)}): {unmatched}")
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
