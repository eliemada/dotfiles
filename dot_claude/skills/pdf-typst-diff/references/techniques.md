# PDF → Typst → Diff — Technique Reference

Rationale for each non-obvious choice in the pipeline. Load this when output quality is wrong and tuning is needed.

## Table of Contents
- [Why Typst (not LaTeX / Markdown)](#why-typst-not-latex--markdown)
- [PDF → Markdown Backends](#pdf--markdown-backends)
- [Markdown → Typst via Pandoc](#markdown--typst-via-pandoc)
- [Diff Granularity](#diff-granularity)
- [Annotated-Typst Markup](#annotated-typst-markup)
- [Tuning Cheat Sheet](#tuning-cheat-sheet)

## Why Typst (not LaTeX / Markdown)

| Format | Pros | Cons |
|---|---|---|
| **Typst** | Compiles in <1s for 50 pages, modern syntax, native Pandoc writer (v3+), purpose-built for re-typesetting | Younger ecosystem; some advanced LaTeX packages have no equivalent |
| LaTeX | Universal, mature | Slow compile, fragile to PDF→source round-tripping, package hell |
| Markdown | Simple, diff-friendly | No layout fidelity; loses structure for typeset output |

For a *diff-and-redline-then-recompile* workflow, Typst is the sweet spot: it's a text format (diffable, git-friendly) AND it renders back to a PDF that looks like a real document — fast.

## PDF → Markdown Backends

### pymupdf4llm (default)

Built on top of PyMuPDF, optimized for LLM ingestion (markdown output that preserves headings, lists, basic tables). Pure-python install, no model download.

- **Best for**: born-digital text PDFs (contracts, reports, books)
- **Avoid for**: scanned documents (no OCR), heavy math, complex multi-column layouts

### marker (`marker-pdf`)

State-of-the-art layout extraction using a fine-tuned vision model + layout-aware reading-order reconstruction. As of late 2025, beats commercial extractors on academic benchmarks.

- **Best for**: academic papers, scientific PDFs, equations, reading-order-sensitive docs
- **Cost**: ~5 GB model, GPU strongly recommended for reasonable throughput
- **Note**: emits markdown by default; passes through Pandoc cleanly

### docling (IBM)

IBM's open-sourced document understanding stack. Particularly strong on tables (TableFormer model) and formula recognition. Cleaner output than marker for table-heavy financial/legal docs.

- **Best for**: tables, formulas, mixed-content business docs
- **Cost**: ~1 GB model, CPU works but slow

### Other backends considered (not exposed)

- **Nougat (Meta)** — purpose-built for academic PDFs, but Meta deprecated it; project is unmaintained as of 2024
- **MinerU (opendatalab)** — strong open option, but the API is moving; revisit in a later skill version
- **Mathpix Convert** — commercial, paid API; out of scope for an open pipeline
- **pdfminer.six / pdfplumber** — text-only, no layout/markdown structure

## Markdown → Typst via Pandoc

Pandoc added a native Typst writer in **v3.0 (2023)**, making this conversion a single CLI invocation:

```
pandoc input.md -f markdown -t typst -o output.typ
```

`pypandoc-binary` bundles a recent Pandoc — no separate install. If `pypandoc` (without `-binary`) is installed instead, the system `pandoc` must be ≥ 3.0 — older versions fail with "unknown output format typst".

The post-processing in `pdf_to_typst.py` strips Pandoc's generator-comment preamble and normalizes blank lines. We deliberately do not rewrite headings, lists, or math — Pandoc's Typst writer handles all of those correctly.

## Diff Granularity

`typst_diff.py` runs at two levels:

### Line-level (`difflib.unified_diff`)

Standard git-style diff. Best for review: pipe it into `delta` / `diff-so-fancy` if you want syntax highlighting in the terminal.

### Word/token-level (`difflib.SequenceMatcher` over tokens)

The annotated Typst output uses token-level granularity because line-level redlining produces visually terrible output: a single-word edit highlights the entire paragraph as both "old" and "new".

Token regex: `\w+|\s+|[^\w\s]` — words, whitespace runs, and individual punctuation as separate tokens. This keeps boundaries intuitive: changing "the cat" → "a cat" produces `#del[the] #ins[a] cat` rather than redlining the whole phrase.

### Character-level (rejected)

Considered for finer granularity. Rejected because:
1. Visual noise — letter-by-letter highlighting on a typo correction is unreadable
2. Performance — SequenceMatcher is O(N·M); character sequences blow up quickly

### Semantic diff (future work)

True semantic diff (paragraph-aware, structure-aware) would require an AST of Typst itself. The official `typst` crate exposes a syntax tree, but no stable Python binding yet. Token-level diff covers ~95% of practical cases.

## Annotated-Typst Markup

```typst
#let ins(body) = highlight(fill: rgb("#c6f6c6"))[#body]
#let del(body) = text(fill: red)[#strike[#body]]
```

Choices:
- **`highlight`** (Typst 0.10+) gives a pale-green background — standard redline convention for additions
- **`text(fill: red) + strike`** for deletions — red strikethrough is the universally-recognized "removed text" marker
- Both are defined as macros at the top of the file so the user can restyle (e.g., for accessibility: switch green → cyan, red → bright-magenta) by editing two lines

Characters escaped inside `#ins[...]` / `#del[...]`: `\`, `#`, `[`, `]`, `$`, `@`. These are the Typst metacharacters that would otherwise break the macro argument or trigger unintended typesetting.

## Tuning Cheat Sheet

| Symptom | Try |
|---|---|
| `.typ` looks like garbled fragments | Switch backend: pymupdf4llm → marker (academic) or docling (tables) |
| Math comes through as `?` or junk | Backend doesn't do math — use marker or docling |
| Tables flattened to comma-separated text | Use docling; marker is second-best |
| Scanned PDF returns empty `.typ` | Pre-OCR with `ocrmypdf input.pdf output.pdf`, or use marker (has internal OCR) |
| Diff redlines whole paragraphs for tiny edits | Already token-level; raise the issue is probably hard line breaks — keep `--unwrap` on (default) |
| `typst compile annotated.typ` errors on a `#ins[...]` | Likely an unescaped `]` inside the inserted text; update `_TYPST_ESCAPE` in `typst_diff.py` |
| Pandoc complains "unknown output format typst" | Pandoc < 3.0; install `pypandoc-binary` or upgrade |
