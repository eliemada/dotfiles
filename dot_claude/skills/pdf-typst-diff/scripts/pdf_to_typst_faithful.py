#!/usr/bin/env python3
"""High-fidelity PDF → Typst: preserves the exact visual appearance.

Two modes:
  - overlay (default): rasterize each page as a high-DPI background PNG,
    then overlay a selectable text layer extracted via PyMuPDF spans.
    Output looks pixel-identical to the source.
  - positioned: skip the background; emit only positioned text + extracted
    images. Editable but loses vector graphics (rules, fills, decorative
    shapes).

Both modes write a `.typ` file plus an `assets/` directory of images. The
.typ uses `#set page(width:Wpt, height:Hpt, margin: 0pt)` and `#place()`
calls so each element lands at its exact source coordinate.

Usage:
  python pdf_to_typst_faithful.py input.pdf --out out.typ --mode overlay --dpi 200
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import fitz  # PyMuPDF


# Characters that must be escaped inside a Typst string literal.
def typst_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def int_to_hex_color(c: int) -> str:
    r, g, b = (c >> 16) & 0xFF, (c >> 8) & 0xFF, c & 0xFF
    return f"#{r:02x}{g:02x}{b:02x}"


def font_weight_from_name(font_name: str) -> str | None:
    """Heuristic: pick a Typst weight from a PDF font subname."""
    n = font_name.lower()
    if "black" in n or "heavy" in n:
        return "900"
    if "bold" in n:
        return "700"
    if "semibold" in n or "demibold" in n:
        return "600"
    if "medium" in n:
        return "500"
    if "light" in n:
        return "300"
    if "thin" in n:
        return "100"
    return None


def font_style_from_name(font_name: str) -> str | None:
    n = font_name.lower()
    if "italic" in n or "oblique" in n:
        return "italic"
    return None


def emit_text_span(span: dict, visible: bool) -> str:
    """One Typst statement that places a text span at its source bbox."""
    text = span["text"]
    if not text:
        return ""
    x0, y0, _, y1 = span["bbox"]
    size_pt = span["size"]
    color_hex = int_to_hex_color(span["color"])
    font_name = span["font"]

    # When the page image already contains the text, render the overlay
    # transparent so the visual stays identical but the text is selectable.
    fill = f'rgb("{color_hex}")' if visible else "rgb(0, 0, 0, 0)"

    weight = font_weight_from_name(font_name)
    style = font_style_from_name(font_name)
    text_args = [f"size: {size_pt:.2f}pt", f"fill: {fill}"]
    if weight:
        text_args.append(f"weight: {weight}")
    if style:
        text_args.append(f'style: "{style}"')

    return (
        f"#place(top + left, dx: {x0:.2f}pt, dy: {y0:.2f}pt, "
        f"text({', '.join(text_args)}, {typst_string(text)}))"
    )


def emit_image_placement(rel_path: str, x: float, y: float, w: float, h: float) -> str:
    return (
        f"#place(top + left, dx: {x:.2f}pt, dy: {y:.2f}pt, "
        f'image("{rel_path}", width: {w:.2f}pt, height: {h:.2f}pt))'
    )


def extract_page_overlay(
    doc: fitz.Document,
    page_idx: int,
    page: fitz.Page,
    assets_dir: Path,
    dpi: int,
) -> list[str]:
    """Rasterize the page as a background PNG and overlay selectable text."""
    out: list[str] = []
    w_pt, h_pt = page.rect.width, page.rect.height

    if page_idx == 0:
        out.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")
        out.append("#set text(font: \"Helvetica\")")
        out.append("")
    else:
        out.append("")
        out.append(f"#pagebreak()")
        out.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")

    # Background: full-page raster.
    zoom = dpi / 72.0
    pix = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)
    bg_path = assets_dir / f"page_{page_idx + 1:03d}_bg.png"
    pix.save(bg_path)
    out.append(emit_image_placement(bg_path.name, 0, 0, w_pt, h_pt))

    # Text overlay: invisible, selectable.
    text_dict = page.get_text("dict")
    for block in text_dict["blocks"]:
        if block.get("type", 0) != 0:
            continue
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                stmt = emit_text_span(span, visible=False)
                if stmt:
                    out.append(stmt)
    return out


def extract_page_positioned(
    doc: fitz.Document,
    page_idx: int,
    page: fitz.Page,
    assets_dir: Path,
) -> list[str]:
    """Emit positioned text + extracted images. No page raster background."""
    out: list[str] = []
    w_pt, h_pt = page.rect.width, page.rect.height

    if page_idx == 0:
        out.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")
        out.append("#set text(font: \"Helvetica\")")
        out.append("")
    else:
        out.append("")
        out.append(f"#pagebreak()")
        out.append(f"#set page(width: {w_pt:.2f}pt, height: {h_pt:.2f}pt, margin: 0pt)")

    # Embedded images at their source bbox.
    for img_idx, info in enumerate(page.get_images(full=True)):
        xref = info[0]
        try:
            rects = page.get_image_rects(xref)
        except Exception:
            rects = []
        if not rects:
            continue
        try:
            pix = fitz.Pixmap(doc, xref)
            if pix.n - pix.alpha > 3:
                pix = fitz.Pixmap(fitz.csRGB, pix)
            img_path = assets_dir / f"page_{page_idx + 1:03d}_img_{img_idx:02d}.png"
            pix.save(img_path)
            pix = None
        except Exception as e:
            print(f"[warn] image xref={xref} extract failed: {e}", file=sys.stderr)
            continue
        for r in rects:
            out.append(emit_image_placement(img_path.name, r.x0, r.y0, r.width, r.height))

    # Visible positioned text.
    text_dict = page.get_text("dict")
    for block in text_dict["blocks"]:
        if block.get("type", 0) != 0:
            continue
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                stmt = emit_text_span(span, visible=True)
                if stmt:
                    out.append(stmt)
    return out


def convert(pdf_path: Path, out_typst: Path, mode: str, dpi: int) -> Path:
    if not pdf_path.exists():
        raise FileNotFoundError(pdf_path)
    if mode not in ("overlay", "positioned"):
        raise ValueError("mode must be 'overlay' or 'positioned'")

    out_typst.parent.mkdir(parents=True, exist_ok=True)
    assets_dir = out_typst.with_suffix("") .parent / f"{out_typst.stem}_assets"
    assets_dir.mkdir(exist_ok=True)

    doc = fitz.open(pdf_path)
    lines: list[str] = []

    # Rewrite image-placement calls so paths are relative to the .typ file.
    for i, page in enumerate(doc):
        if mode == "overlay":
            page_lines = extract_page_overlay(doc, i, page, assets_dir, dpi)
        else:
            page_lines = extract_page_positioned(doc, i, page, assets_dir)
        # Patch asset paths to be relative to the .typ output directory.
        rel_prefix = assets_dir.name + "/"
        page_lines = [
            ln.replace('image("', f'image("{rel_prefix}')
            if ln.startswith("#place(top + left,") and "image(\"" in ln
            else ln
            for ln in page_lines
        ]
        lines.extend(page_lines)
    doc.close()

    out_typst.write_text("\n".join(lines) + "\n")
    return out_typst


def main() -> int:
    ap = argparse.ArgumentParser(description="High-fidelity PDF → Typst.")
    ap.add_argument("pdf", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--mode", choices=["overlay", "positioned"], default="overlay")
    ap.add_argument("--dpi", type=int, default=200, help="DPI for the page background raster (overlay mode only)")
    args = ap.parse_args()

    path = convert(args.pdf, args.out, args.mode, args.dpi)
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
