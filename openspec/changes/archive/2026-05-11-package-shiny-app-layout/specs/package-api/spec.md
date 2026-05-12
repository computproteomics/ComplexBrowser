## ADDED Requirements

### Requirement: Package Data Asset Layout

The system SHALL keep runtime data assets under package-managed directories and
SHALL keep historical source data out of package builds.

#### Scenario: Install-time data assets

- **GIVEN** the package is installed
- **WHEN** R, CLI, or Shiny workflows need bundled runtime data
- **THEN** prepared databases SHALL be available under `inst/extdata`
- **AND** reusable example inputs SHALL be available under `inst/extdata/examples`
- **AND** Shiny-specific example inputs SHALL be available under `inst/shiny/data`

#### Scenario: Historical data snapshots

- **GIVEN** historical source data, old prepared database snapshots, or generated
  legacy documentation
- **WHEN** the package is built
- **THEN** those files SHALL remain outside the repository root under
  `data-raw/legacy`
- **AND** they SHALL NOT be included in package builds

### Requirement: Packaged Shiny App Location

The system SHALL provide the Shiny app from the package-managed
`inst/shiny/` directory and SHALL expose an R helper for launching the installed
app.

#### Scenario: Run app from repository checkout

- **GIVEN** a source checkout of the package
- **WHEN** a developer runs the Shiny app from `inst/shiny`
- **THEN** the app SHALL find its UI, server, global startup file, helper files,
  static assets, report template, and bundled example input relative to the app
  directory

#### Scenario: Run app after package installation

- **GIVEN** the package is installed
- **WHEN** an R user invokes the package Shiny app helper
- **THEN** the system SHALL launch the app from `system.file("shiny", package = "complexbrowser")`
- **AND** the app SHALL not require root-level `ui.R`, `server.R`, `Global.R`,
  `www`, `styling`, or `QCreport.rmd` files
