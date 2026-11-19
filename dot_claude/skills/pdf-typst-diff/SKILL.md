---
name: pdf-typst-diff
description: Edit text inside an existing PDF while keeping its exact look, convert a PDF to editable Typst, or diff two PDFs with redlines. Use when the user wants to change specific words, dates or amounts in their own PDF without retyping it, wants a Typst copy of a PDF (pixel-identical or reflowed), or wants to compare two versions of a document with unified, side-by-side or redline output. Not for reading or summarising PDFs (use docling-pdf or the Read tool) or for building new PDFs from scratch.
---

# PDF ↔ Typst: edit, convert, diff

Four self-contained scripts in `scripts/`. Each declares its own Python dependencies
(PEP 723), so run them with `uv run` and nothing needs installing except `uv` and the
`typst` CLI. Paths below are relative to this skill's directory.

| Task | Script | Output |
|---|---|---|
| Change text in a PDF, keep the look | `pdf_edit.py` | `.typ` + background assets → compile to PDF |
| Pixel-identical, editable Typst copy | `pdf_to_typst_faithful.py` | `.typ` with raster background + selectable text |
| Reflowed, clean Typst (re-typesetting) | `pdf_to_typst.py` | semantic `.typ` via Markdown + Pandoc |
| Compare two documents | `typst_diff.py` | `unified.diff`, `side_by_side.html`, `annotated.typ`, `report.json` |

## Editing text in a PDF (most common)

The script masks each matched span with a colour sampled from behind it and overlays the
new text at the same position, size, weight and colour. That's why logos, coloured headers
and layout survive: nothing outside the matched spans is regenerated.

1. **Find the exact strings.** Edit keys must match text spans in the PDF exactly (or be
   substrings of one span). Look at the spans first, because a value often appears in
   several formats (`12/03/26` and `12.03.2026`) and each format needs its own key:
   ```bash
   uv run --with pymupdf python -c "import fitz,sys; [print(s['text']) for p in fitz.open(sys.argv[1]) for b in p.get_text('dict')['blocks'] for l in b.get('lines',[]) for s in l['spans']]" input.pdf
   ```
2. **Write the edits** as JSON `{old: new}`:
   ```json
   { "Jane Doe": "Jane Smith", "2026-01-15": "2026-02-01", "Draft": "Final" }
   ```
3. **Apply and compile:**
   ```bash
   uv run scripts/pdf_edit.py input.pdf --edits edits.json --out edited.typ
   typst compile edited.typ edited.pdf
   ```
4. **Check the report.** The script prints `matched` and `unmatched` keys. Fix any unmatched
   key (usually a format variant or a span boundary) and rerun before showing the result.

Within one span, replacements apply left to right, so one span holding two dates can have
both changed in a single pass. Only edit documents the user is entitled to change: this
reproduces the original's appearance faithfully, so it must not be used to alter documents
issued by someone else (official records, third-party invoices, IDs).

## Converting a PDF to Typst

Pick by what the user wants to do with the result:

- **Looks identical** ("keep the logo", "exact same colours"):
  `uv run scripts/pdf_to_typst_faithful.py in.pdf --out in.typ --mode overlay --dpi 200`.
  The page is rasterised as a background and the text layer is transparent but selectable.
  DPI: 150 draft, 200 default, 300 print. Assets go to `<out_stem>_assets/`; keep them with the `.typ`.
- **Every element editable, no raster** (plain vector forms): `--mode positioned`.
- **Re-typeset from scratch, reflow welcome** (papers, contracts):
  `uv run scripts/pdf_to_typst.py in.pdf --out in.typ [--backend pymupdf4llm|marker|docling] [--keep-md]`.
  `pymupdf4llm` (default) is fast and fine for born-digital PDFs. Scanned pages, equations or
  complex tables need `docling` or `marker`, which download large models. Add them with
  `uv run --with docling …` or `uv run --with marker-pdf …`, and tell the user first that this takes a while.

## Diffing two documents

Convert both PDFs **in the same mode** first. Mixing modes makes every line differ.

```bash
uv run scripts/typst_diff.py old.typ new.typ --out diff_out
typst compile diff_out/annotated.typ diff_out/annotated.pdf   # optional redline PDF
```

It produces a line-level unified diff, plus a word-level annotated Typst file (green
insertions, red strikethrough deletions), so a one-word change doesn't redline a whole
paragraph. Single newlines are unwrapped before diffing to cut reflow noise.

## When something goes wrong

- **No text extracted**: the PDF is scanned. Use `--backend docling` (OCR) or pre-OCR with `ocrmypdf`.
- **Equations come out as garbage / tables are flattened**: use `docling` (best for tables) or `marker`.
- **`typst` not found**: `brew install typst` (the Mac and Linux Brewfiles already include it).

Background on backend choice, the Pandoc Typst writer and the diff conventions:
`references/techniques.md`. Read it only when tuning output quality.
