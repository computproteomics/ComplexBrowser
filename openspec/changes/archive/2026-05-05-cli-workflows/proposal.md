## Why

ComplexBrowser now has package-level QC and complex-analysis APIs, but users and external software still need to run those workflows through R code or the Shiny app. A command-line workflow is needed for reproducible batch runs, pipelines, and headless complex analysis.

## What Changes

- Add a command-line entry point for the installed `complexbrowser` package.
- Support a `qc` command that reads a proteomics input table, runs QC/statistics, and writes stable output files.
- Support a `complex` command that reads the same input table, runs QC/statistics, runs complex analysis, and writes stable output files.
- Keep the CLI as a thin wrapper over existing package APIs; it must not duplicate scientific calculations or source Shiny files.
- Preserve current input semantics for condition/replicate layout, log2 conversion, grouped measurements, q-value handling, normalization, design, database selection, and organism selection.

## Intended Callers

- Shell workflows running `Rscript` or an installed package executable.
- External software that needs CSV/RDS outputs without launching Shiny.
- R users who want a non-interactive API surface for batch processing.

## Compatibility

- Existing CSV/TXT input layout semantics remain unchanged.
- Bundled CORUM and EBI Complex Portal databases continue to load through package accessors.
- CLI output filenames are new and do not change existing Shiny download filenames.
- Scientific methods, thresholds, and database content are not changed.

## Non-Goals

- Do not redesign the Shiny UI.
- Do not add new complex-analysis statistics or change scoring.
- Do not make plotting/report generation part of the first CLI workflow.
- Do not add runtime package installation behavior.
