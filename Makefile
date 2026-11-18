PYTHON ?= uv run --locked python
JULIA ?= julia
.PHONY: test check play demo theory-figs theory-check fmt lint typecheck check-style
test check play demo:
	$(PYTHON) scripts/check.py $@

# Regenerates the plotted figures and the measured-values table of docs/theory (one command, no packages).
theory-figs:
	mkdir -p docs/theory/figures
	$(JULIA) --project=. --startup-file=no scripts/theory_figs.jl docs/theory/figures

# Fails when a statement of docs/theory has no figure, a link is broken, or a referenced function or test is gone.
theory-check:
	$(PYTHON) scripts/theory-check.py

# Formatter, linter and type checker: JuliaFormatter, Aqua and JET (pinned in style/Manifest.toml)
# for Julia; Ruff (every rule) and mypy strict for the Python scripts (pinned in uv.lock). No ignores.
STYLE = $(JULIA) --project=style --startup-file=no style/check.jl
fmt:
	$(STYLE) fmt
	uv run --locked ruff format scripts
	uv run --locked ruff check --fix scripts
lint:
	$(STYLE) format
	$(STYLE) lint
	uv run --locked ruff format --check scripts
	uv run --locked ruff check scripts
typecheck:
	$(STYLE) typecheck
	uv run --locked mypy
check-style: lint typecheck
