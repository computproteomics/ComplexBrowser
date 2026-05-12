## Why

The Shiny app entry files and assets still lived at the repository root after
the package refactor. That layout is convenient for a standalone Shiny app, but
it is not the expected structure for an installable R package and makes the
installed app harder to locate with package-managed paths.

## What Changes

- Move the runnable Shiny app into `inst/shiny/`.
- Keep Shiny-only plotting and UI helpers under `inst/shiny/R/`.
- Move the QC report template, static assets, CSS, and bundled Shiny example
  input under the app directory.
- Add a package helper that runs the installed app from its package-managed
  location.
- Move remaining root-level data files into package-managed example locations
  or source-only legacy storage.
- Update documentation and OpenSpec context to describe the package layout.

## Compatibility

- Shiny UI, QC, complex-analysis calculations, downloads, and browser messaging
  should keep their existing behavior.
- Package APIs and CLI workflows are unchanged.
- The bundled example data remains available to the Shiny app, but it uses a
  package-friendly filename under `inst/shiny/data/`.
- Root-level historical data snapshots are retained under `data-raw/legacy/`
  and excluded from package builds.

## Non-Goals

- Do not redesign the Shiny UI.
- Do not change scientific calculations, thresholds, or bundled database
  content.
- Do not turn Shiny plotting helpers into public package APIs.
