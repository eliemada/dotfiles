#!/usr/bin/env bash
# Convert a PDF to Markdown using docling via uvx.
# Usage: convert_pdf.sh <pdf_path> [output_dir]
#
# If output_dir is not provided, defaults to /tmp/docling/<stem>/
# Images are exported as referenced PNGs in the output directory.

set -euo pipefail

PDF_PATH="$1"

if [ ! -f "$PDF_PATH" ]; then
  echo "Error: File not found: $PDF_PATH" >&2
  exit 1
fi

STEM=$(basename "$PDF_PATH" .pdf)
OUTPUT_DIR="${2:-/tmp/docling/$STEM}"

mkdir -p "$OUTPUT_DIR"

echo "Converting: $PDF_PATH"
echo "Output dir: $OUTPUT_DIR"

uvx docling convert \
  "$PDF_PATH" \
  --to md \
  --image-export-mode referenced \
  --ocr \
  --output "$OUTPUT_DIR"

echo ""
echo "Done. Output files:"
ls -la "$OUTPUT_DIR"
echo ""
echo "Markdown file:"
find "$OUTPUT_DIR" -name "*.md" -type f
