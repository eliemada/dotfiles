---
paths:
  - "**/*.py"
  - "**/*.pyi"
  - "**/pyproject.toml"
---
# Python

- Tooling is Astral: `uv` for envs, deps and running (`uv run`, `uv add`, `uvx`), `ruff`
  for lint + format, `ty` for type checking. Don't introduce pip/venv/black/mypy/poetry
  into a uv project.
- One-off scripts: put PEP 723 inline metadata at the top and run them with `uv run script.py`,
  so they carry their own dependencies.
- Type-annotate public functions. Use `@dataclass(frozen=True)` or `NamedTuple` for records
  that shouldn't change.
- Tests: `pytest`, run with `uv run pytest`. For numeric code, check behaviour with
  tolerances (`pytest.approx`, `np.testing`) and edge cases (empty, NaN, single row).
- Data work: prefer polars (lazy where it helps) for new pipelines; keep pandas where the
  project already uses it. Watch for look-ahead and silent index alignment in time series.
- Use `logging` instead of `print` in library code; `print` is fine in scripts and notebooks.
