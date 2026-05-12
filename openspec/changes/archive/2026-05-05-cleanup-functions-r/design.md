## Design

Move app-only helpers into files under `inst/shiny/R/` so they are no longer mixed with package computation modules under `R/` and no longer live in a root catch-all file.

Planned files:

- `inst/shiny/R/plots_qc.R`: QC plot helpers used by tab 1.
- `inst/shiny/R/plots_complex.R`: complex-analysis plot and summary display helpers used by tab 2.
- `inst/shiny/R/ui_helpers.R`: Shiny UI helper utilities such as selectize tooltips.

`ui.R` will source these helper files after loading app dependencies. `server.R` can continue calling the same helper names, minimizing app churn.

Tests that use legacy `Functions.R` will be rewritten to rely on stored fixtures and current package helpers. Once references are gone, delete `Functions.R`.

## Validation

Run package tests, Shiny smoke tests for load example / complex analysis / download controls, `R CMD build`, `R CMD check`, and OpenSpec validation.
