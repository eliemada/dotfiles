# Docling CLI Reference

Docling is run via `uvx docling` (no install needed — uv handles it).

## Basic usage

```bash
uvx docling <source> --to md --output <dir>
```

## Key options

| Flag | Values | Default | Purpose |
|------|--------|---------|---------|
| `--to` | md, json, html, text, doctags | md | Output format |
| `--image-export-mode` | placeholder, embedded, referenced | embedded | How images are handled |
| `--ocr` / `--no-ocr` | — | ocr | OCR bitmap content |
| `--force-ocr` | — | no-force-ocr | Replace existing text with OCR |
| `--ocr-engine` | auto, easyocr, ocrmac, rapidocr, tesserocr, tesseract | auto | OCR engine |
| `--ocr-lang` | comma-separated | — | OCR languages |
| `--pipeline` | legacy, standard, vlm, asr | standard | Processing pipeline |
| `--tables` / `--no-tables` | — | tables | Extract table structure |
| `--table-mode` | fast, accurate | accurate | Table extraction quality |
| `--pdf-backend` | pypdfium2, dlparse_v1, dlparse_v2, dlparse_v4 | dlparse_v4 | PDF parsing backend |
| `--pdf-password` | TEXT | — | Password for protected PDFs |
| `--device` | auto, cpu, cuda, mps | auto | Accelerator |
| `--num-threads` | INTEGER | 4 | Thread count |
| `--document-timeout` | FLOAT | — | Per-document timeout (seconds) |
| `--output` | PATH | . | Output directory |

## Image export modes

- **placeholder**: Only marks image positions in output (no actual images)
- **embedded**: Base64-encodes images inline (large output files)
- **referenced**: Exports images as separate PNG files, referenced from markdown (best for Claude — images can be read with Read tool)

## Tips

- For scanned PDFs or image-heavy docs, `--force-ocr` may improve results
- `--ocr-engine ocrmac` is fastest on macOS
- `--pipeline vlm` uses vision-language models for better layout understanding but is slower
- `--table-mode fast` speeds up processing when table accuracy is less critical
