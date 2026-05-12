## Design

The Shiny app becomes a packaged app rooted at `inst/shiny/`:

- `inst/shiny/ui.R`: shinydashboard interface and UI outputs.
- `inst/shiny/server.R`: Shiny reactive orchestration over package APIs.
- `inst/shiny/Global.R`: app startup database loading.
- `inst/shiny/R/`: app-only plotting and UI helper functions.
- `inst/shiny/QCreport.rmd`: QC report template.
- `inst/shiny/www/` and `inst/shiny/styling/`: static assets and CSS.
- `inst/shiny/data/`: bundled app example input.
- `inst/extdata/examples/`: reusable example inputs for R and CLI workflows.
- `data-raw/legacy/`: historical source data, old database snapshots, and
  generated legacy documents excluded from package builds.

`inst/shiny/app_paths.R` centralizes app-relative and source-checkout-relative
paths. The app uses app-relative paths for report templates, static CSS, helper
sources, and example input. During source-tree development it can still find the
package `R/` files when the package is not installed.

The exported `complexbrowser_run_app()` helper launches
`system.file("shiny", package = "complexbrowser")` through `shiny::runApp()`.
This gives R users an obvious installed-package entry point while keeping shell
and CLI workflows separate.

## Code Structure

The move is mechanical and should not add new analysis branches to the Shiny
server. Path handling is isolated in a small helper file so `ui.R`, `server.R`,
and `Global.R` do not grow additional nested file-location logic.

## Validation

- Source `inst/shiny/Global.R`, `inst/shiny/ui.R`, and `inst/shiny/server.R`
  from a checkout.
- Confirm `complexbrowser_run_app` is exported and documented.
- Confirm root-level data files have been moved to `inst/` or `data-raw/legacy/`.
- Run package tests and R CMD check.
- Validate OpenSpec documents.
