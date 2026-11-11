PYTHON ?= python3.14
JULIA ?= julia
.PHONY: test check play demo theory-figs theory-check
test check play demo:
	$(PYTHON) scripts/check.py $@

# Regenerates the plotted figures and the measured-values table of docs/theory (one command, no packages).
theory-figs:
	mkdir -p docs/theory/figures
	$(JULIA) --project=. --startup-file=no scripts/theory_figs.jl docs/theory/figures

# Fails when a statement of docs/theory has no figure, a link is broken, or a referenced function or test is gone.
theory-check:
	$(PYTHON) scripts/theory-check.py
