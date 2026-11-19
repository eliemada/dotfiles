---
name: docling-pdf
description: Extract a PDF into clean Markdown with docling (OCR, table structure, figures exported as images). Use when the plain Read tool isn't enough, meaning a scanned or image-only PDF, tables or multi-column layouts that must stay structured, a long paper or report you want as a reusable .md file, or text that must be fed into another tool. Not needed for quickly reading a short born-digital PDF (use Read), and not for editing or creating PDFs (use pdf-typst-diff or the pdf skill).
---

# Docling: PDF → Markdown

docling runs layout analysis, table-structure recognition and OCR, so it keeps tables and
reading order that simple text extraction loses. It's slow, though (seconds to minutes per
document, plus a one-time model download of about 1 GB on first use). Try the Read tool first
for short, text-based PDFs, and reach for this when structure or OCR matters.

## Convert

```bash
bash scripts/convert_pdf.sh "/path/to/file.pdf" [output_dir]
```

(The path is relative to this skill's directory.) It runs `uvx docling convert`, so nothing needs
installing besides `uv`. By default it writes to `/tmp/docling/<stem>/`:

- `<stem>.md`: the full document as Markdown
- `*.png`: figures, referenced from the Markdown

Then Read the `.md` file. Read the referenced images only if the question depends on a figure.
On the first run, tell the user the model download may take a few minutes, so a silent wait
doesn't look like a hang.

## Options worth knowing

Pass extra flags by running docling directly:

```bash
uvx docling convert "/path/file.pdf" --to md --image-export-mode referenced --ocr --output /tmp/docling/<stem> [flags]
```

| Situation | Flag |
|---|---|
| Scanned PDF and the text came out poor | `--force-ocr` |
| macOS, want faster OCR | `--ocr-engine ocrmac` (macOS only) |
| Very large document times out | `--document-timeout 600` |
| Password-protected | `--pdf-password '<password>'` (ask the user; never guess) |
| Only some pages needed | `--page-range 1-10` |

Full CLI notes: `references/docling-cli.md`.
