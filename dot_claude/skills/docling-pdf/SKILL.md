---
name: docling-pdf
description: >
  Convert PDF documents to Markdown using docling via uv for high-quality text extraction with OCR, table detection, and image export.
  Use this skill whenever Claude needs to extract text or content from a PDF file — whether to read it, analyze it, answer questions about it, or process its contents.
  Triggers: user provides a PDF file path, asks to read/extract/convert/parse a PDF, references PDF content, or asks questions that require reading a PDF.
  Do NOT use for creating or editing PDFs — only for extracting content from existing PDFs.
---

# Docling PDF Extraction

Extract text from PDFs using `docling` via `uvx` (zero-install, uv handles the package).

## Workflow

### 1. Convert the PDF

Run the bundled script:

```bash
bash <skill_path>/scripts/convert_pdf.sh "/path/to/file.pdf"
```

This outputs to `/tmp/docling/<filename>/` with:
- `<filename>.md` — the full extracted Markdown
- Referenced PNG images in the same directory

### 2. Read the extracted Markdown

After conversion, read the `.md` file with the Read tool to get the PDF contents.

### 3. Read extracted images if needed

If the markdown references images (e.g., `![](image_0.png)`), read them with the Read tool using the full path in `/tmp/docling/<filename>/`.

### 4. Save to memory if the user requests it

If the user wants the extracted text persisted across sessions, save the markdown content to `~/.claude/projects/<project>/memory/` using Write tool.

## Handling special cases

- **Password-protected PDFs**: Add `--pdf-password <pass>` to the docling command
- **Scanned/image PDFs with poor results**: Re-run with `--force-ocr` flag
- **macOS OCR optimization**: Add `--ocr-engine ocrmac` for faster processing
- **Large PDFs timing out**: Add `--document-timeout 300` for a 5-minute timeout

For the full CLI reference, see [references/docling-cli.md](references/docling-cli.md).

## Manual invocation

If the script doesn't fit the need, run docling directly:

```bash
uvx docling "/path/to/file.pdf" --to md --image-export-mode referenced --ocr --output /tmp/docling/<stem>
```
