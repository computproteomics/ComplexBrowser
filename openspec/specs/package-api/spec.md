# package-api Specification

## Purpose

Define the reusable R package APIs that run ComplexBrowser workflows without requiring Shiny, while preserving current scientific results and output shapes.
## Requirements
### Requirement: Package Callable Workflows

The system SHALL expose package-level R functions that run core ComplexBrowser workflows without requiring a Shiny session.

#### Scenario: Run QC workflow without Shiny

- **GIVEN** a valid quantitative proteomics input table
- **AND** condition, replicate, grouping, q-value, log2, and design settings
- **WHEN** the caller invokes the package QC workflow
- **THEN** the system SHALL return QC statistics and a merged statistics table without reading Shiny inputs or mutating Shiny state

#### Scenario: Run complex analysis without Shiny

- **GIVEN** QC statistics from the package QC workflow
- **AND** a selected complex database, species, and threshold settings
- **WHEN** the caller invokes the package complex-analysis workflow
- **THEN** the system SHALL return filtered statistics, matched complexes, complex scores, and display-ready complex tables without requiring Shiny

### Requirement: Stable Result Objects

The system SHALL return named result objects whose fields are stable enough for Shiny, R scripts, tests, and future command-line callers.

#### Scenario: QC result object

- **WHEN** the package QC workflow succeeds
- **THEN** the returned object SHALL include prepared input data, calculated statistics, merged display table, and workflow metadata

#### Scenario: Complex result object

- **WHEN** the package complex-analysis workflow succeeds
- **THEN** the returned object SHALL include filtered statistics, filtered database rows, display table, scoring summaries, selected database, selected species, and threshold metadata

### Requirement: Refactor Result Parity

The system SHALL preserve current Shiny workflow results when Shiny is rewired to package APIs.

#### Scenario: Example QC parity

- **GIVEN** the bundled example input and fixed QC settings
- **WHEN** the pre-refactor workflow and package QC workflow are compared
- **THEN** protein identifiers, column names, row counts, and rounded display values SHALL match
- **AND** unrounded numeric values SHALL match within 0.1% relative tolerance

#### Scenario: Example complex-analysis parity

- **GIVEN** the bundled example input, fixed database selection, fixed species, and fixed thresholds
- **WHEN** the pre-refactor workflow and package complex-analysis workflow are compared
- **THEN** matched complex identifiers, display table columns, coverage values, scores, and summary outputs SHALL match within 0.1% relative tolerance for unrounded numeric values

### Requirement: Explicit Error Handling

The system SHALL report invalid package API inputs with explicit errors instead of Shiny-only validation side effects.

#### Scenario: Missing input file

- **WHEN** a package workflow is called with a missing file path
- **THEN** the system SHALL return or raise an error that identifies the missing path

#### Scenario: Invalid workflow parameters

- **WHEN** a package workflow is called with unsupported condition, replicate, database, species, threshold, or design settings
- **THEN** the system SHALL return or raise an error that identifies the invalid parameter

### Requirement: Side-Effect Boundaries

Core package computation functions SHALL be free of implicit UI, filesystem, and global-state side effects, and legacy app helper files SHALL NOT be required for package API execution.

#### Scenario: Package workflows without legacy Functions file

- **WHEN** package QC, complex-analysis, export, or CLI workflows run
- **THEN** they SHALL execute without sourcing `Functions.R`
- **AND** they SHALL NOT depend on Shiny plotting helper definitions

### Requirement: Package Database Assets

The system SHALL provide prepared database assets from the `complexbrowser` package instead of relying on repository-root RDS paths.

#### Scenario: Load bundled CORUM database

- **WHEN** a caller requests the bundled CORUM database through the package API
- **THEN** the system SHALL load the prepared CORUM RDS asset from package-managed data paths
- **AND** the loaded database content SHALL match the pre-refactor prepared CORUM database content

#### Scenario: Load bundled EBI Complex Portal database

- **WHEN** a caller requests the bundled EBI Complex Portal database through the package API
- **THEN** the system SHALL load the prepared EBI Complex Portal RDS asset from package-managed data paths
- **AND** the loaded database content SHALL match the pre-refactor prepared EBI Complex Portal database content

### Requirement: Package Data Asset Layout

The system SHALL keep runtime data assets under package-managed directories and SHALL keep historical source data out of package builds.

#### Scenario: Install-time data assets

- **GIVEN** the package is installed
- **WHEN** R, CLI, or Shiny workflows need bundled runtime data
- **THEN** prepared databases SHALL be available under `inst/extdata`
- **AND** reusable example inputs SHALL be available under `inst/extdata/examples`
- **AND** Shiny-specific example inputs SHALL be available under `inst/shiny/data`

#### Scenario: Historical data snapshots

- **GIVEN** historical source data, old prepared database snapshots, or generated legacy documentation
- **WHEN** the package is built
- **THEN** those files SHALL remain outside the repository root under `data-raw/legacy`
- **AND** they SHALL NOT be included in package builds

### Requirement: Workflow Vignettes

The system SHALL provide concise package vignettes for the primary non-Shiny workflows.

#### Scenario: QC vignette

- **WHEN** an R user opens the QC workflow vignette
- **THEN** the vignette SHALL show how to load bundled example input data
- **AND** it SHALL show how to run `complexbrowser_run_qc`
- **AND** it SHALL show how to inspect and export QC results

#### Scenario: Complex-analysis vignette

- **WHEN** an R user opens the complex-analysis workflow vignette
- **THEN** the vignette SHALL show how to run QC as prerequisite input
- **AND** it SHALL show how to run `complexbrowser_run_complex_analysis`
- **AND** it SHALL show how to inspect, summarize, and export complex-analysis results

### Requirement: Packaged Shiny App Location

The system SHALL provide the Shiny app from the package-managed `inst/shiny/` directory and SHALL expose an R helper for launching the installed app.

#### Scenario: Run app from repository checkout

- **GIVEN** a source checkout of the package
- **WHEN** a developer runs the Shiny app from `inst/shiny`
- **THEN** the app SHALL find its UI, server, global startup file, helper files, static assets, report template, and bundled example input relative to the app directory

#### Scenario: Run app after package installation

- **GIVEN** the package is installed
- **WHEN** an R user invokes the package Shiny app helper
- **THEN** the system SHALL launch the app from `system.file("shiny", package = "complexbrowser")`
- **AND** the app SHALL not require root-level `ui.R`, `server.R`, `Global.R`, `www`, `styling`, or `QCreport.rmd` files

#### Scenario: Run app in Docker

- **GIVEN** the Docker image is built from the package source
- **WHEN** Shiny Server starts in the container
- **THEN** the image SHALL serve the Shiny app copied from `system.file("shiny", package = "complexbrowser")`
- **AND** the image SHALL not copy root-level Shiny app files or root-level data files

### Requirement: R CMD Check Diagnostics

The package SHALL maintain a reproducible R package check with no
package-owned warnings or notes.

#### Scenario: Package-owned diagnostics are fixed

- **GIVEN** the package source tree
- **WHEN** `R CMD build` and `R CMD check --no-manual` run in an environment
  with required system and R dependencies available
- **THEN** the check SHALL complete without package-owned warnings or notes
- **AND** package examples, tests, and vignettes SHALL still run

#### Scenario: Environment-owned diagnostics are documented

- **GIVEN** a check diagnostic caused by network access, unavailable external
  repositories, missing system tools, or local permissions
- **WHEN** the diagnostic cannot be fixed by changing package source
- **THEN** the diagnostic SHALL be documented with its cause and reproduction
  condition
- **AND** it SHALL NOT be hidden by weakening package validation

