---
name: pdf-typst-diff
description: Convert, edit, or diff PDFs via Typst. Three capabilities — (1) Faithful PDF-to-Typst conversion that produces a pixel-identical, recompilable .typ with selectable text overlaid on a rasterized background. (2) Targeted text edits driven by a JSON mapping of old strings to new strings — finds matching spans, masks each with a sampled-background-color rect, and overlays the new text at the same position/size/weight/color so any invoice, contract, or form can be edited while preserving logos, colors, and layout. (3) Two-PDF diff producing unified, side-by-side, and annotated-with-redlines outputs. Use when the user wants to change values in a PDF (dates, names, amounts) while keeping the original look, make a Typst copy of a PDF, or compare two PDFs. Triggers include "edit this PDF", "change the date or name or email in this invoice", "convert this PDF to Typst", "make an exact Typst copy", "diff these PDFs", "redline in Typst", "PDF to editable document keeping the same look".
---

# PDF → Typst → Diff

## Overview

Three capabilities, all driven by Python scripts + the `typst` CLI:

1. **Edit a PDF in place** (`pdf_edit.py`) — takes a JSON `{old: new}` edits map, finds matching text spans, masks the original raster with a sampled-bg-color rect, overlays the new text. Works on white pages and on coloured/dark headers because the mask color is sampled per-span.
2. **Convert a PDF to Typst** (`pdf_to_typst_faithful.py` for visual parity, `pdf_to_typst.py` for semantic/markdown) — produces editable `.typ` source.
3. **Diff two PDFs as Typst** (`typst_diff.py`) — unified, HTML side-by-side, and annotated redline outputs.

## Editing a PDF (most common use case)

```bash
# 1. Write the edits as a JSON object: keys = exact strings in the PDF.
cat > edits.json <<'EOF'
{
  "Jane Doe": "Jane Smith",
  "jane.doe@example.com": "jane.smith@example.com",
  "12.03.2026": "18.05.2026"
}
EOF

# 2. Generate edited Typst (+ background assets).
python scripts/pdf_edit.py invoice.pdf --edits edits.json --out invoice_edited.typ

# 3. Compile to PDF — output is visually identical except for the edits.
typst compile invoice_edited.typ invoice_edited.pdf
```

The script prints `matched` and `unmatched` keys so the caller knows whether each edit landed. Substring matches are applied left-to-right within each span, so a single span like `"période du 09.03.2026 au 08.04.2026"` can have both dates replaced in one pass.

### How Claude should drive this on any invoice

1. Run `pdf_to_typst_faithful.py` (or just `python -c "import fitz; ..."`) to inspect the actual text spans — the EDITS keys must match the spans exactly (or be substrings of them).
2. Write an `edits.json` based on the user's request, mapping every variant of a value that appears in the PDF (dates often appear in multiple formats: `12/03/26` AND `12.03.2026`).
3. Run `pdf_edit.py`, check the `unmatched` list, refine the JSON if anything failed to match.
4. `typst compile` and show the result.

## Conversion + Diff Modes

| Mode | Script | Output looks like | Editable? |
|---|---|---|---|
| **Faithful** (default for visual parity) | `pdf_to_typst_faithful.py --mode overlay` | Pixel-identical to source PDF (logos, colors, layout, decorative shapes all preserved) | Text overlay is selectable & searchable; reposition by editing `#place(...)` coords |
| **Positioned** | `pdf_to_typst_faithful.py --mode positioned` | Text + raster images at exact coordinates, no vector backgrounds | Fully editable |
| **Semantic** | `pdf_to_typst.py` | Clean Typst headings/paragraphs, layout reflowed | Highly editable; ideal for re-typesetting from scratch |

The diff stage (`typst_diff.py`) is mode-agnostic — it accepts any two `.typ` files and emits unified, side-by-side HTML, and annotated-Typst redline outputs.

## When to Use Each Mode

- **Faithful overlay** — user says "make it look the same", "exact same images/colors", "keep the logo", or wants to embed the PDF visually while keeping selectable text.
- **Positioned** — pure-vector documents (forms with no decorative graphics) where the user wants every element editable and no embedded raster.
- **Semantic** — re-typesetting a paper, contract, or report from scratch in Typst, where reflow is desirable.

## Quick Start

```bash
# 1. Install deps (one-time)
pip install pymupdf pymupdf4llm pypandoc-binary
brew install typst        # or: cargo install --git https://github.com/typst/typst

# 2a. Faithful conversion — pixel-identical Typst
python scripts/pdf_to_typst_faithful.py input.pdf --out input.typ --mode overlay --dpi 200

# 2b. Semantic conversion — clean editable Typst
python scripts/pdf_to_typst.py input.pdf --out input.typ

# 3. Diff two .typ files (same mode on both sides recommended)
python scripts/typst_diff.py old.typ new.typ --out ./diff_out

# 4. (Optional) render the annotated Typst to PDF
typst compile ./diff_out/annotated.typ ./diff_out/annotated.pdf
```

Outputs in `--out`:
- `unified.diff` — git-style unified diff
- `side_by_side.html` — visual side-by-side report
- `annotated.typ` — original new.typ with insertions/deletions marked
- `report.json` — per-block change statistics

## Faithful Mode Details

`scripts/pdf_to_typst_faithful.py` uses PyMuPDF's structured extraction (`page.get_text("dict")` for spans with font/size/color, `page.get_images()` for embedded images). In **overlay** mode the page is also rasterized to a high-DPI PNG and placed as a background; the text layer is rendered with `rgb(0,0,0,0)` (fully transparent) so it remains selectable but does not visually duplicate the rasterized text.

Page setup:
```typst
#set page(width: <Wpt>, height: <Hpt>, margin: 0pt)
#place(top + left, dx: 0pt, dy: 0pt, image("page_001_bg.png", width: <W>pt, height: <H>pt))
#place(top + left, dx: <x>pt, dy: <y>pt, text(size: <s>pt, fill: rgb(0,0,0,0), "selectable text"))
```

DPI guidance: 150 for drafts, 200 for general use (default), 300 for print-grade output, 600 for forensic/archival fidelity.

Assets go into a sibling directory named `<out_stem>_assets/` next to the `.typ` file. Keep them together when distributing.

## Workflow

### Step 1 — Pick a conversion backend (semantic mode only)

`scripts/pdf_to_typst.py` accepts `--backend {pymupdf4llm,marker,docling}`. Picking the right one matters more than any other choice:

| Backend | Strengths | Weaknesses | When to use |
|---|---|---|---|
| **pymupdf4llm** (default) | Fast, pure-python, no ML model download, robust on digital PDFs | Weaker on complex tables, multi-column layouts | Born-digital text PDFs (contracts, reports) |
| **marker** | SOTA layout, equations, tables; preserves reading order | ~5 GB model download, GPU recommended | Academic papers, structured docs |
| **docling** | IBM's open release; excellent table extraction, formula recognition | ~1 GB model, CPU-OK but slow | Tables, scientific documents |

All three emit Markdown; Pandoc converts Markdown → Typst with `pandoc -f markdown -t typst`.

### Step 2 — Convert PDF to Typst

```bash
python scripts/pdf_to_typst.py input.pdf --out input.typ --backend pymupdf4llm
```

The script:
1. Runs the chosen backend → intermediate Markdown
2. Pipes Markdown through Pandoc with `--to typst`
3. Post-processes the `.typ` (strips Pandoc's preamble noise, fixes heading levels)

Pass `--keep-md` to also write `input.md` for debugging.

### Step 3 — Diff two Typst files

`scripts/typst_diff.py` runs at two granularities simultaneously:

- **Line-level** unified diff (`difflib.unified_diff`) for the raw report
- **Word-level** (`difflib.SequenceMatcher` on tokens) for the annotated Typst — finer-grained than diffing whole lines so single-word edits don't redline the whole paragraph

Annotated Typst uses:
```typst
#let ins(body) = highlight(fill: rgb("#c6f6c6"))[#body]
#let del(body) = text(fill: red)[#strike[#body]]
```

These render as green-highlighted insertions and red strikethrough deletions when compiled with `typst compile`.

### Step 4 — Render the redlined PDF (optional)

```bash
typst compile ./diff_out/annotated.typ ./diff_out/annotated.pdf
```

Typst is dramatically faster than LaTeX — a 50-page document typically compiles in under a second.

## Common Pitfalls

- **Pandoc not found**: `pypandoc-binary` ships the binary; if you used `pypandoc` instead, install Pandoc separately via `brew install pandoc`.
- **Scanned PDFs**: pymupdf4llm extracts no text from images. Use marker or docling (both run OCR internally), or pre-OCR with `ocrmypdf`.
- **Equations rendered as garbage**: switch to marker or docling — pymupdf4llm has no math model.
- **Tables flattened**: docling is the best table extractor; marker is second.
- **Diff is noisy because of reflow**: PDFs often add hard line breaks mid-paragraph. The script unwraps single-newline breaks before diffing; multi-newline paragraph breaks are preserved.

## State-of-the-Art Rationale

See [references/techniques.md](references/techniques.md) for the why behind each backend choice, the Pandoc Typst writer (added in Pandoc 3.x), word-level vs character-level diff, and the annotated-Typst color/markup conventions.

## Resources

- `scripts/pdf_edit.py` — **targeted text editing of any PDF**, driven by `{old: new}` JSON. Preserves layout/colors/logos via sampled-bg-color masking. Default for any "change X in this PDF" task.
- `scripts/pdf_to_typst_faithful.py` — pixel-identical PDF → Typst (overlay or positioned mode) using PyMuPDF span/image extraction. Use when the user wants the Typst source itself.
- `scripts/pdf_to_typst.py` — semantic PDF → Typst (pymupdf4llm | marker | docling backends + Pandoc Typst writer). Use when re-typesetting from scratch with reflow.
- `scripts/typst_diff.py` — line + word-level diff with unified, HTML, JSON, and annotated-Typst outputs.
- `references/techniques.md` — SOTA rationale, mode/backend selection guide, and tuning cheat sheet
